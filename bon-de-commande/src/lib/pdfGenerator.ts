import jsPDF from "jspdf";
import autoTable from "jspdf-autotable";

const BLEU = [0, 48, 135] as [number,number,number];
const BLANC: [number,number,number] = [255,255,255];
const NOIR: [number,number,number] = [0,0,0];

export function generatePDF(commande: any) {
  const doc = new jsPDF({ orientation: "portrait", unit: "mm", format: "a4" });
  const W = doc.internal.pageSize.getWidth();

  doc.setFont("helvetica","black");
  doc.setFontSize(28);
  doc.setTextColor(...BLEU);
  doc.text("INDUNI", 14, 20);
  doc.setFillColor(...BLEU);
  doc.circle(27, 24, 3, "F");

  doc.setFillColor(240,240,240);
  doc.rect(14, 30, W-28, 14, "F");
  doc.setDrawColor(200,200,200);
  doc.rect(14, 30, W-28, 14, "S");
  doc.setFont("helvetica","bold");
  doc.setFontSize(13);
  doc.setTextColor(...NOIR);
  doc.text("BON DE COMMANDE N° " + commande.numero, W/2, 38, {align:"center"});
  doc.setFont("helvetica","normal");
  doc.setFontSize(10);
  doc.text("Du " + commande.date, W/2, 43, {align:"center"});

  const bY = 48, bH = 44, halfW = (W-28)/2;
  doc.setFillColor(...BLEU);
  doc.rect(14, bY, halfW, 8, "F");
  doc.rect(14+halfW+2, bY, halfW-2, 8, "F");
  doc.setTextColor(...BLANC);
  doc.setFont("helvetica","bold");
  doc.setFontSize(9);
  doc.text("CLIENT", 14+halfW/2, bY+5.5, {align:"center"});
  doc.text("FOURNISSEUR", 14+halfW+2+(halfW-2)/2, bY+5.5, {align:"center"});

  doc.setDrawColor(...BLEU);
  doc.setLineWidth(0.4);
  doc.rect(14, bY, halfW, bH, "S");
  doc.rect(14+halfW+2, bY, halfW-2, bH, "S");

  doc.setTextColor(...NOIR);
  doc.setFont("helvetica","bold");
  doc.setFontSize(10);
  doc.text(commande.societe || "", 16, bY+14);
  doc.setFont("helvetica","normal");
  doc.setFontSize(8.5);
  let cy = bY + 20;
  if (commande.responsable) { doc.setFont("helvetica","bold"); doc.text("Contact :", 16, cy); doc.setFont("helvetica","normal"); doc.text(commande.responsable, 38, cy); cy += 5; }
  if (commande.nomChantier) { doc.setFont("helvetica","bold"); doc.text("Chantier :", 16, cy); doc.setFont("helvetica","normal"); doc.text(commande.nomChantier, 38, cy); cy += 5; }
  if (commande.codeChantier) { doc.setFont("helvetica","bold"); doc.text("Code chantier :", 16, cy); doc.setFont("helvetica","normal"); doc.text(commande.codeChantier, 46, cy); cy += 5; }
  if (commande.adresseLivraison) {
    doc.setFont("helvetica","bold"); doc.text("Adresse de livraison :", 16, cy); cy += 4;
    doc.setFont("helvetica","normal");
    const lines = commande.adresseLivraison.split("\n");
    lines.forEach((l: string) => { doc.text("  "+l, 16, cy); cy += 4; });
  }

  const fx = 14+halfW+4;
  doc.setFont("helvetica","bold");
  doc.setFontSize(10);
  doc.text(commande.fournisseur || "", fx, bY+14);
  doc.setFont("helvetica","normal");
  doc.setFontSize(8.5);
  if (commande.adresseFournisseur) {
    doc.setFont("helvetica","bold"); doc.text("Adresse :", fx, bY+20);
    doc.setFont("helvetica","normal");
    const lines = commande.adresseFournisseur.split("\n");
    lines.forEach((l: string, i: number) => { doc.text(l, fx, bY+26+i*4); });
  }

  const tableY = bY + bH + 6;
  autoTable(doc, {
    startY: tableY,
    head: [["Désignation", "Date livr.", "Qté", "Unité", "Rabais", "Prix", "Montant"]],
    body: commande.lignes.map((l: any) => [
      l.designation,
      l.dateLivraison ? new Date(l.dateLivraison).toLocaleDateString("fr-CH") : "",
      String(l.quantite),
      l.unite,
      l.rabais > 0 ? l.rabais + "%" : "",
      Number(l.prixUnitaire).toFixed(2),
      Number(l.montant || l.quantite * l.prixUnitaire).toFixed(2),
    ]),
    headStyles: { fillColor: BLEU, textColor: BLANC, fontStyle: "bold", fontSize: 9 },
    bodyStyles: { fontSize: 9 },
    columnStyles: {
      0: { cellWidth: "auto" },
      1: { halign: "center", cellWidth: 22 },
      2: { halign: "center", cellWidth: 14 },
      3: { halign: "center", cellWidth: 14 },
      4: { halign: "center", cellWidth: 14 },
      5: { halign: "right", cellWidth: 22 },
      6: { halign: "right", cellWidth: 22 },
    },
    alternateRowStyles: { fillColor: [245, 248, 255] },
    margin: { left: 14, right: 14 },
    didDrawPage: () => {},
  });

  const finalY = (doc as any).lastAutoTable.finalY;
  doc.setFillColor(240, 244, 255);
  doc.rect(14, finalY, W-28, 9, "F");
  doc.setDrawColor(...BLEU);
  doc.rect(14, finalY, W-28, 9, "S");
  doc.setFont("helvetica","bold");
  doc.setFontSize(10);
  doc.setTextColor(...BLEU);
  doc.text("Montant total commande H.T.", 16, finalY+6);
  doc.text("CHF", W/2, finalY+6, {align:"center"});
  doc.text(Number(commande.totalHT).toLocaleString("fr-CH",{minimumFractionDigits:2}), W-14, finalY+6, {align:"right"});

  let iy = finalY + 18;
  doc.setFont("helvetica","bold");
  doc.setFontSize(12);
  doc.setTextColor(...NOIR);
  doc.text("Informations complémentaires sur le chantier", 14, iy);
  iy += 8;
  doc.setFont("helvetica","normal");
  doc.setFontSize(9);

  if (commande.nomContactChantier || commande.numeroContactChantier) {
    doc.setFont("helvetica","bold"); doc.text("Contremaître :", 14, iy); doc.setFont("helvetica","normal");
    doc.text((commande.nomContactChantier||"") + (commande.numeroContactChantier ? " - " + commande.numeroContactChantier : ""), 52, iy);
    iy += 5;
  }
  if (commande.technicien) {
    doc.setFont("helvetica","bold"); doc.text("Technicien :", 14, iy); doc.setFont("helvetica","normal");
    doc.text(commande.technicien, 52, iy); iy += 5;
  }
  if (commande.contraintes) {
    doc.setFont("helvetica","bold"); doc.text("Contraintes du chantier :", 14, iy); doc.setFont("helvetica","normal");
    doc.text(commande.contraintes, 52, iy); iy += 5;
  }
  if (commande.notes) {
    iy += 2; doc.setFont("helvetica","italic"); doc.setFontSize(8.5);
    doc.text(commande.notes, 14, iy, {maxWidth: W-28}); iy += 8;
  }

  iy += 4;
  doc.setFont("helvetica","normal"); doc.setFontSize(9); doc.setTextColor(80,80,80);
  doc.text("Adresse de facturation :", 14, iy); iy += 5;
  doc.setTextColor(...NOIR);
  doc.text(commande.societe || "", 14, iy); iy += 4;
  if (commande.adresseSociete) {
    const lines = commande.adresseSociete.split("\n");
    lines.forEach((l: string) => { doc.text(l, 14, iy); iy += 4; });
  }
  if (commande.emailFacturation) { doc.text(commande.emailFacturation, 14, iy); iy += 4; }

  iy += 8;
  doc.setDrawColor(0,0,0); doc.setLineWidth(0.3);
  doc.line(14, iy+12, 80, iy+12);
  doc.setFontSize(9); doc.setTextColor(80,80,80);
  doc.text(commande.responsable || "", 14, iy+17);

  const footY = doc.internal.pageSize.getHeight() - 8;
  doc.setFontSize(7); doc.setTextColor(160,160,160);
  doc.text("Bon de commande " + commande.numero + " — Généré le " + new Date().toLocaleDateString("fr-CH") + " | INDUNI & Cie SA", W/2, footY, {align:"center"});

  doc.save(commande.numero + ".pdf");

  const s = encodeURIComponent("Bon de commande " + commande.numero + " — " + (commande.nomChantier||""));
  const b = encodeURIComponent("Bonjour,\n\nVeuillez trouver ci-joint le bon de commande " + commande.numero + " du " + commande.date + ".\n\nChantier : " + (commande.nomChantier||"") + " (" + (commande.codeChantier||"") + ")\nTotal HT : CHF " + Number(commande.totalHT).toFixed(2) + "\n\nCordialement,\n" + (commande.responsable||""));
  window.location.href = "mailto:" + commande.emailFournisseur + "?subject=" + s + "&body=" + b;
}