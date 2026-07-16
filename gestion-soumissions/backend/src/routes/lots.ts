import { Router } from "express";
import { z } from "zod";
import { prisma } from "../lib/prisma";
import { requireAuth } from "../middleware/auth";
import { LOT_SUPPLIER_STATUS_VALUES, LOT_STATUS_VALUES } from "../lib/constants";
import { buildEmailForLot } from "../lib/email-template";

export const lotsRouter = Router();
lotsRouter.use(requireAuth);

const createLotSchema = z.object({
  title: z.string().min(1),
  cfcRef: z.string().optional(),
  workType: z.string().optional(),
  categories: z.array(z.string()).optional(),
});

// POST /api/submissions/:submissionId/lots
lotsRouter.post("/submissions/:submissionId/lots", async (req, res) => {
  const parsed = createLotSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: parsed.error.issues[0].message });
  const { title, cfcRef, workType, categories } = parsed.data;

  const submission = await prisma.submission.findUnique({ where: { id: req.params.submissionId } });
  if (!submission) return res.status(404).json({ error: "Soumission introuvable." });

  const count = await prisma.lot.count({ where: { submissionId: submission.id } });
  const lot = await prisma.lot.create({
    data: { submissionId: submission.id, title, cfcRef, workType, position: count },
  });

  if (categories && categories.length > 0) {
    const suppliers = await prisma.sourcingSupplier.findMany({ where: { category: { in: categories } } });
    const seen = new Set<string>();
    for (const s of suppliers) {
      const key = s.supplierName.toUpperCase();
      if (seen.has(key)) continue;
      seen.add(key);
      await prisma.lotSupplier.create({
        data: {
          lotId: lot.id,
          sourcingSupplierId: s.id,
          supplierName: s.supplierName,
          email: s.email,
          status: "suggested",
        },
      });
    }
  }

  const full = await prisma.lot.findUnique({ where: { id: lot.id }, include: { suppliers: true, suivi: true } });
  res.status(201).json(full);
});

const updateLotSchema = z.object({
  title: z.string().min(1).optional(),
  cfcRef: z.string().optional(),
  workType: z.string().optional(),
  status: z.enum(LOT_STATUS_VALUES).optional(),
});

lotsRouter.patch("/lots/:id", async (req, res) => {
  const parsed = updateLotSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: parsed.error.issues[0].message });

  const lot = await prisma.lot.update({ where: { id: req.params.id }, data: parsed.data });
  res.json(lot);
});

lotsRouter.delete("/lots/:id", async (req, res) => {
  await prisma.lot.delete({ where: { id: req.params.id } });
  res.status(204).send();
});

const addSupplierSchema = z.object({
  sourcingSupplierId: z.string().optional(),
  supplierName: z.string().min(1),
  email: z.string().email().optional(),
});

lotsRouter.post("/lots/:id/suppliers", async (req, res) => {
  const parsed = addSupplierSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: parsed.error.issues[0].message });

  const lotSupplier = await prisma.lotSupplier.create({
    data: { lotId: req.params.id, status: "validated", ...parsed.data },
  });
  res.status(201).json(lotSupplier);
});

const updateLotSupplierSchema = z.object({
  status: z.enum(LOT_SUPPLIER_STATUS_VALUES).optional(),
  selectedForEmail: z.boolean().optional(),
});

lotsRouter.patch("/lot-suppliers/:id", async (req, res) => {
  const parsed = updateLotSupplierSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: parsed.error.issues[0].message });

  const lotSupplier = await prisma.lotSupplier.update({ where: { id: req.params.id }, data: parsed.data });
  res.json(lotSupplier);
});

lotsRouter.delete("/lot-suppliers/:id", async (req, res) => {
  await prisma.lotSupplier.delete({ where: { id: req.params.id } });
  res.status(204).send();
});

// GET /api/lots/:id/email — génère le contenu de l'e-mail groupé pour les fournisseurs sélectionnés d'un lot.
lotsRouter.get("/lots/:id/email", async (req, res) => {
  const lot = await prisma.lot.findUnique({
    where: { id: req.params.id },
    include: { suppliers: true, submission: true },
  });
  if (!lot) return res.status(404).json({ error: "Lot introuvable." });

  const recipients = lot.suppliers.filter((s) => s.selectedForEmail && s.email).map((s) => s.email!);
  const body = buildEmailForLot(lot);
  res.json({ to: recipients, subject: `Demande de prix — ${lot.title}`, body });
});
