import { Router } from "express";
import { z } from "zod";
import { prisma } from "../lib/prisma";
import { requireAuth } from "../middleware/auth";

export const sourcingRouter = Router();
sourcingRouter.use(requireAuth);

sourcingRouter.get("/categories", async (_req, res) => {
  const rows = await prisma.sourcingSupplier.findMany({
    select: { category: true },
    distinct: ["category"],
    orderBy: { category: "asc" },
  });
  res.json(rows.map((r) => r.category));
});

sourcingRouter.get("/", async (req, res) => {
  const category = typeof req.query.category === "string" ? req.query.category : undefined;
  const q = typeof req.query.q === "string" ? req.query.q : undefined;

  const suppliers = await prisma.sourcingSupplier.findMany({
    where: {
      ...(category ? { category } : {}),
      ...(q ? { supplierName: { contains: q } } : {}),
    },
    orderBy: [{ category: "asc" }, { supplierName: "asc" }],
    take: 200,
  });
  res.json(suppliers);
});

const suggestSchema = z.object({
  categories: z.array(z.string()).min(1),
  limit: z.number().int().positive().max(50).optional(),
});

// Une catégorie -> tous les fournisseurs connus pour cette catégorie, dédupliqués par nom (comme le prototype).
sourcingRouter.post("/suggest", async (req, res) => {
  const parsed = suggestSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: parsed.error.issues[0].message });
  const { categories, limit = 8 } = parsed.data;

  const rows = await prisma.sourcingSupplier.findMany({
    where: { category: { in: categories } },
    orderBy: { category: "asc" },
  });

  const seen = new Set<string>();
  const out = [];
  for (const row of rows) {
    const key = row.supplierName.toUpperCase();
    if (seen.has(key)) continue;
    seen.add(key);
    out.push(row);
    if (out.length >= limit) break;
  }
  res.json(out);
});

const createCustomSchema = z.object({
  category: z.string().min(1),
  supplierName: z.string().min(1),
  email: z.string().email().optional(),
  note: z.string().optional(),
});

sourcingRouter.post("/", async (req, res) => {
  const parsed = createCustomSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: parsed.error.issues[0].message });

  const supplier = await prisma.sourcingSupplier.create({
    data: { ...parsed.data, isCustom: true },
  });
  res.status(201).json(supplier);
});
