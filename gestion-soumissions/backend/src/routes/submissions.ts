import { Router } from "express";
import { z } from "zod";
import { prisma } from "../lib/prisma";
import { requireAuth } from "../middleware/auth";

export const submissionsRouter = Router();
submissionsRouter.use(requireAuth);

submissionsRouter.get("/", async (_req, res) => {
  const submissions = await prisma.submission.findMany({
    orderBy: { updatedAt: "desc" },
    include: { owner: { select: { name: true } }, _count: { select: { lots: true } } },
  });
  res.json(submissions);
});

const createSchema = z.object({
  name: z.string().min(1),
  ref: z.string().optional(),
  lieu: z.string().optional(),
  entite: z.string().optional(),
  contactName: z.string().optional(),
  contactEmail: z.string().email().optional(),
  dateLimiteRetour: z.coerce.date().optional(),
  lienDocument: z.string().optional(),
});

submissionsRouter.post("/", async (req, res) => {
  const parsed = createSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: parsed.error.issues[0].message });

  const submission = await prisma.submission.create({
    data: { ...parsed.data, createdBy: req.user!.userId },
  });
  res.status(201).json(submission);
});

submissionsRouter.get("/:id", async (req, res) => {
  const submission = await prisma.submission.findUnique({
    where: { id: req.params.id },
    include: {
      lots: {
        orderBy: { position: "asc" },
        include: { suppliers: true, suivi: true },
      },
    },
  });
  if (!submission) return res.status(404).json({ error: "Soumission introuvable." });
  res.json(submission);
});

const updateSchema = z.object({
  name: z.string().min(1).optional(),
  ref: z.string().optional(),
  lieu: z.string().optional(),
  entite: z.string().optional(),
  contactName: z.string().optional(),
  contactEmail: z.string().email().optional(),
  dateLimiteRetour: z.coerce.date().optional(),
  lienDocument: z.string().optional(),
  status: z.string().optional(),
  statutApprobation: z.string().optional(),
});

submissionsRouter.patch("/:id", async (req, res) => {
  const parsed = updateSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: parsed.error.issues[0].message });

  const submission = await prisma.submission.update({
    where: { id: req.params.id },
    data: parsed.data,
  });
  res.json(submission);
});

submissionsRouter.delete("/:id", async (req, res) => {
  await prisma.submission.delete({ where: { id: req.params.id } });
  res.status(204).send();
});
