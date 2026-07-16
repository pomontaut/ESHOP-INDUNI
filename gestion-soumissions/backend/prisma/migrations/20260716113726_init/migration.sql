-- CreateTable
CREATE TABLE "User" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "email" TEXT NOT NULL,
    "passwordHash" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- CreateTable
CREATE TABLE "Submission" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "name" TEXT NOT NULL,
    "ref" TEXT,
    "lieu" TEXT,
    "entite" TEXT,
    "contactName" TEXT,
    "contactEmail" TEXT,
    "dateLimiteRetour" DATETIME,
    "lienDocument" TEXT,
    "status" TEXT NOT NULL DEFAULT 'open',
    "statutApprobation" TEXT,
    "createdBy" TEXT NOT NULL,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL,
    CONSTRAINT "Submission_createdBy_fkey" FOREIGN KEY ("createdBy") REFERENCES "User" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "Lot" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "submissionId" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "cfcRef" TEXT,
    "workType" TEXT,
    "status" TEXT NOT NULL DEFAULT 'proposed',
    "position" INTEGER NOT NULL DEFAULT 0,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL,
    CONSTRAINT "Lot_submissionId_fkey" FOREIGN KEY ("submissionId") REFERENCES "Submission" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "SourcingSupplier" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "category" TEXT NOT NULL,
    "supplierName" TEXT NOT NULL,
    "email" TEXT,
    "note" TEXT,
    "isCustom" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- CreateTable
CREATE TABLE "LotSupplier" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "lotId" TEXT NOT NULL,
    "sourcingSupplierId" TEXT,
    "supplierName" TEXT NOT NULL,
    "email" TEXT,
    "status" TEXT NOT NULL DEFAULT 'suggested',
    "selectedForEmail" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "LotSupplier_lotId_fkey" FOREIGN KEY ("lotId") REFERENCES "Lot" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "LotSupplier_sourcingSupplierId_fkey" FOREIGN KEY ("sourcingSupplierId") REFERENCES "SourcingSupplier" ("id") ON DELETE SET NULL ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "SuiviRow" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "lotId" TEXT NOT NULL,
    "lotSupplierId" TEXT NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'A_envoyer',
    "montantEstimatif" REAL,
    "montant" REAL,
    "conforme" BOOLEAN NOT NULL DEFAULT true,
    "sentDate" DATETIME,
    "relanceDate" DATETIME,
    "dateRetour" DATETIME,
    "notes" TEXT,
    "offerFileUrl" TEXT,
    "retained" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL,
    CONSTRAINT "SuiviRow_lotId_fkey" FOREIGN KEY ("lotId") REFERENCES "Lot" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "SuiviRow_lotSupplierId_fkey" FOREIGN KEY ("lotSupplierId") REFERENCES "LotSupplier" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);

-- CreateIndex
CREATE UNIQUE INDEX "User_email_key" ON "User"("email");

-- CreateIndex
CREATE INDEX "SourcingSupplier_category_idx" ON "SourcingSupplier"("category");

-- CreateIndex
CREATE INDEX "LotSupplier_lotId_idx" ON "LotSupplier"("lotId");

-- CreateIndex
CREATE INDEX "SuiviRow_lotId_idx" ON "SuiviRow"("lotId");
