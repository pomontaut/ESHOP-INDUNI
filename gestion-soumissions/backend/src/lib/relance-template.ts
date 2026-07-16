import { Lot, Submission, SuiviRow } from "@prisma/client";

function formatDateFr(d: Date | null): string {
  if (!d) return "prochainement communiquée";
  return d.toLocaleDateString("fr-CH", { day: "2-digit", month: "2-digit", year: "numeric" });
}

// Porté depuis relanceEmailBody dans le prototype HTML (ligne ~2480).
export function buildRelanceEmail(row: SuiviRow, lot: Lot, submission: Submission): string {
  const deadline = formatDateFr(submission.dateLimiteRetour);
  return `Bonjour,

Nous nous permettons de revenir vers vous au sujet de notre demande de prix pour ${lot.title}${
    lot.cfcRef ? ` (réf. CFC ${lot.cfcRef})` : ""
  }, pour laquelle nous n'avons pas encore eu le plaisir de recevoir votre offre.

La date limite de retour ayant été fixée au ${deadline}, nous vous serions très reconnaissants de bien vouloir nous transmettre votre proposition dans les meilleurs délais.

N'hésitez pas à nous contacter si vous avez besoin d'informations complémentaires pour finaliser votre chiffrage.

En vous remerciant par avance et avec nos meilleures salutations.

Service achats
Induni`;
}

export function businessDayBefore(date: Date): Date {
  const d = new Date(date);
  d.setDate(d.getDate() - 1);
  while (d.getDay() === 0 || d.getDay() === 6) d.setDate(d.getDate() - 1);
  return d;
}
