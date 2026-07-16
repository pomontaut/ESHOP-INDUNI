import { PrismaClient } from "@prisma/client";
import sourcing from "./seed-data/sourcing.json";

const prisma = new PrismaClient();

type SourcingRow = { category: string; supplier: string; email: string | null; note: string | null };

async function main() {
  const rows = sourcing as SourcingRow[];
  const existing = await prisma.sourcingSupplier.count();
  if (existing > 0) {
    console.log(`SourcingSupplier already seeded (${existing} rows) — skipping.`);
    return;
  }

  await prisma.sourcingSupplier.createMany({
    data: rows.map((r) => ({
      category: r.category,
      supplierName: r.supplier,
      email: r.email ?? undefined,
      note: r.note ?? undefined,
      isCustom: false,
    })),
  });

  console.log(`Seeded ${rows.length} sourcing suppliers.`);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
