export type User = { id: string; email: string; name: string };

export type Submission = {
  id: string;
  name: string;
  ref: string | null;
  lieu: string | null;
  entite: string | null;
  contactName: string | null;
  contactEmail: string | null;
  dateLimiteRetour: string | null;
  lienDocument: string | null;
  status: string;
  statutApprobation: string | null;
  createdBy: string;
  createdAt: string;
  updatedAt: string;
  owner?: { name: string };
  _count?: { lots: number };
  lots?: Lot[];
};

export type LotSupplier = {
  id: string;
  lotId: string;
  sourcingSupplierId: string | null;
  supplierName: string;
  email: string | null;
  status: "suggested" | "validated" | "dismissed";
  selectedForEmail: boolean;
};

export type SuiviRow = {
  id: string;
  lotId: string;
  lotSupplierId: string;
  status: string;
  montantEstimatif: number | null;
  montant: number | null;
  conforme: boolean;
  sentDate: string | null;
  relanceDate: string | null;
  dateRetour: string | null;
  notes: string | null;
  offerFileUrl: string | null;
  retained: boolean;
};

export type Lot = {
  id: string;
  submissionId: string;
  title: string;
  cfcRef: string | null;
  workType: string | null;
  status: "proposed" | "validated";
  position: number;
  suppliers: LotSupplier[];
  suivi: SuiviRow[];
};

export type SourcingSupplier = {
  id: string;
  category: string;
  supplierName: string;
  email: string | null;
  note: string | null;
  isCustom: boolean;
};

export const SUIVI_STATUS_OPTS: [string, string][] = [
  ["A_envoyer", "À envoyer"],
  ["Envoye", "Envoyé"],
  ["Relance1", "Relancé (1)"],
  ["Relance2", "Relancé (2)"],
  ["OffreRecue", "Offre reçue"],
  ["Retenu", "Retenu"],
  ["Decline", "Décliné"],
];
