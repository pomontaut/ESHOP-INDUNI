import { Lot, Submission } from "@prisma/client";

type LotWithSubmission = Lot & { submission: Submission };

function formatDateFr(d: Date | null): string {
  if (!d) return "[date limite]";
  return d.toLocaleDateString("fr-CH", { day: "2-digit", month: "2-digit", year: "numeric" });
}

// Porté depuis EMAIL_TEMPLATE dans le prototype HTML (outil_sourcing_soumission_40.html, ligne ~251).
export function buildEmailForLot(lot: LotWithSubmission): string {
  const p = lot.submission;
  const refLine = [p.ref, p.name, p.lieu].filter(Boolean).join(" - ") || "[Réf. projet] - [Nom du projet] - [Ville]";
  const planLine = [p.ref, p.name, p.lieu].filter(Boolean).join(" - ") || "[Nom du projet] - [Ville]";
  const contactLine =
    [p.contactName, p.contactEmail].filter(Boolean).join(" - ") || "[PRENOM NOM] - [email]";
  const deadline = formatDateFr(p.dateLimiteRetour);
  const documentLine = p.lienDocument
    ? `\nEnsemble des documents de la soumission :   ${p.lienDocument}\n`
    : "";

  return `DATE DE REPONSE SOUHAITEE : ${deadline}

Bonjour,

Merci de bien vouloir nous transmettre votre offre pour les prestations décrites selon soumission ci-annexée (${lot.title}).

N'hésitez pas à chiffrer l'ensemble des positions qui vous intéressent et à proposer des variantes qui vous semblent pertinentes.

Plans :   ${planLine}
${documentLine}MERCI DE MENTIONNER LES REFERENCES SUIVANTES SUR VOTRE MAIL DE RETOUR : ${refLine}
Contact en cas de questions : ${contactLine}

Avec nos meilleures salutations.


\t\tService achats
Avenue des Grandes-Communes 6 | 1213 Petit-Lancy
www.induni.ch`;
}
