import fs from "fs";
import path from "path";

const DB_PATH = path.join(process.cwd(), "data", "commandes.json");

export interface LigneCommande {
  designation: string;
  dateLivraison: string;
  quantite: number;
  unite: string;
  rabais: number;
  prixUnitaire: number;
  montant: number;
}

export interface BonDeCommande {
  id: string;
  numero: string;
  date: string;
  fournisseur: string;
  adresseFournisseur: string;
  emailFournisseur: string;
  societe: string;
  adresseSociete: string;
  responsable: string;
  emailResponsable: string;
  emailFacturation: string;
  nomChantier: string;
  codeChantier: string;
  adresseLivraison: string;
  nomContactChantier: string;
  numeroContactChantier: string;
  technicien: string;
  contraintes: string;
  lignes: LigneCommande[];
  totalHT: number;
  tva: number;
  totalTTC: number;
  notes: string;
  createdAt: string;
}

export function getAllCommandes(): BonDeCommande[] {
  try {
    const content = fs.readFileSync(DB_PATH, "utf-8");
    return JSON.parse(content);
  } catch {
    return [];
  }
}

export function saveCommande(commande: BonDeCommande): void {
  const commandes = getAllCommandes();
  commandes.unshift(commande);
  fs.writeFileSync(DB_PATH, JSON.stringify(commandes, null, 2));
}

export function getNextNumero(): string {
  const commandes = getAllCommandes();
  const year = new Date().getFullYear();
  const count = commandes.filter((c) => c.numero.startsWith(`BC-${year}`)).length;
  return `BC-${year}-${String(count + 1).padStart(4, "0")}`;
}