import { Router } from "express";
import { z } from "zod";
import { prisma } from "../lib/prisma";
import { requireAuth } from "../middleware/auth";
import { SUIVI_STATUS_VALUES } from "../lib/constants";
import { buildRelanceEmail } from "../lib/relance-template";

export const suiviRouter = Router();
suiviRouter.use(requireAuth);

const createSchema = z.object({
  lotSupplierId: z.string().min(1),
});

// POST /api/lots/:lotId/suivi — crée une ligne de suivi pour un fournisseur du lot.
suiviRouter.post("/lots/:lotId/suivi", async (req, res) => {
  const parsed = createSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: parsed.error.issues[0].message });

  const row = await prisma.suiviRow.create({
    data: { lotId: req.params.lotId, lotSupplierId: parsed.data.lotSupplierId },
  });
  res.status(201).json(row);
});

const updateSchema = z.object({
  status: z.enum(SUIVI_STATUS_VALUES as [string, ...string[]]).optional(),
  montantEstimatif: z.number().nullable().optional(),
  montant: z.number().nullable().optional(),
  conforme: z.boolean().optional(),
  sentDate: z.coerce.date().nullable().optional(),
  relanceDate: z.coerce.date().nullable().optional(),
  dateRetour: z.coerce.date().nullable().optional(),
  notes: z.string().optional(),
  offerFileUrl: z.string().optional(),
});

suiviRouter.patch("/suivi/:id", async (req, res) => {
  const parsed = updateSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: parsed.error.issues[0].message });

  const row = await prisma.suiviRow.update({ where: { id: req.params.id }, data: parsed.data });
  res.json(row);
});

// PATCH /api/suivi/:id/retain — marque cette offre comme retenue et dé-sélectionne les autres du même lot.
suiviRouter.patch("/suivi/:id/retain", async (req, res) => {
  const row = await prisma.suiviRow.findUnique({ where: { id: req.params.id } });
  if (!row) return res.status(404).json({ error: "Ligne de suivi introuvable." });

  await prisma.$transaction([
    prisma.suiviRow.updateMany({ where: { lotId: row.lotId }, data: { retained: false } }),
    prisma.suiviRow.update({ where: { id: row.id }, data: { retained: true } }),
  ]);
  res.status(204).send();
});

suiviRouter.delete("/suivi/:id", async (req, res) => {
  await prisma.suiviRow.delete({ where: { id: req.params.id } });
  res.status(204).send();
});

// GET /api/suivi/:id/relance-email — génère le texte de relance pour un fournisseur n'ayant pas répondu.
suiviRouter.get("/suivi/:id/relance-email", async (req, res) => {
  const row = await prisma.suiviRow.findUnique({
    where: { id: req.params.id },
    include: { lot: { include: { submission: true } }, lotSupplier: true },
  });
  if (!row) return res.status(404).json({ error: "Ligne de suivi introuvable." });

  const body = buildRelanceEmail(row, row.lot, row.lot.submission);
  const nextStatus = row.status === "Relance1" ? "Relance2" : "Relance1";
  res.json({
    to: row.lotSupplier.email,
    subject: `Relance — Demande de prix${row.lot.cfcRef ? " CFC " + row.lot.cfcRef : ""} — ${row.lot.title}`,
    body,
    nextStatus,
  });
});

// GET /api/submissions/:id/suivi/export.csv
suiviRouter.get("/submissions/:submissionId/suivi/export.csv", async (req, res) => {
  const lots = await prisma.lot.findMany({
    where: { submissionId: req.params.submissionId },
    include: { suivi: { include: { lotSupplier: true } } },
  });

  const escape = (v: unknown) => `"${(v ?? "").toString().replace(/"/g, '""')}"`;
  const header = [
    "Lot",
    "Ref CFC",
    "Fournisseur",
    "Statut",
    "Montant estimatif",
    "Montant",
    "Conforme",
    "Date retour",
    "Retenu",
    "Notes",
  ];
  const lines = [header.map(escape).join(",")];
  for (const lot of lots) {
    for (const row of lot.suivi) {
      lines.push(
        [
          lot.title,
          lot.cfcRef ?? "",
          row.lotSupplier.supplierName,
          row.status,
          row.montantEstimatif ?? "",
          row.montant ?? "",
          row.conforme ? "Oui" : "Non",
          row.dateRetour ? row.dateRetour.toISOString().slice(0, 10) : "",
          row.retained ? "Oui" : "Non",
          row.notes ?? "",
        ]
          .map(escape)
          .join(","),
      );
    }
  }

  res.setHeader("Content-Type", "text/csv; charset=utf-8");
  res.setHeader("Content-Disposition", `attachment; filename="suivi.csv"`);
  res.send(lines.join("\n"));
});
