"use client";
import { useState } from "react";
import { generatePDF } from "../lib/pdfGenerator";

interface Ligne {
  designation: string;
  dateLivraison: string;
  quantite: number;
  unite: string;
  rabais: number;
  prixUnitaire: number;
}

const DEFAULT_FORM = {
  societe: "INDUNI & CIE SA",
  adresseSociete: "Avenue des Grandes-Communes 6\n1213 Petit-Lancy",
  emailFacturation: "facturation@induni.ch",
  responsable: "",
  emailResponsable: "",
  fournisseur: "",
  adresseFournisseur: "",
  emailFournisseur: "",
  nomChantier: "",
  codeChantier: "",
  adresseLivraison: "",
  nomContactChantier: "",
  numeroContactChantier: "",
  technicien: "",
  contraintes: "",
  notes: "",
};

export default function Home() {
  const [form, setForm] = useState(DEFAULT_FORM);
  const [lignes, setLignes] = useState<Ligne[]>([
    { designation: "", dateLivraison: "", quantite: 1, unite: "u", rabais: 0, prixUnitaire: 0 },
  ]);
  const [loading, setLoading] = useState(false);
  const [success, setSuccess] = useState<string | null>(null);
  const [tab, setTab] = useState<"formulaire"|"historique">("formulaire");
  const [historique, setHistorique] = useState<any[]>([]);

  const totalHT = lignes.reduce((s, l) => {
    const montant = l.quantite * l.prixUnitaire * (1 - l.rabais / 100);
    return s + montant;
  }, 0);

  function updateLigne(i: number, field: keyof Ligne, value: string | number) {
    setLignes(prev => { const n = [...prev]; n[i] = { ...n[i], [field]: value }; return n; });
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setSuccess(null);
    const now = new Date();
    const payload = {
      ...form,
      date: now.toLocaleDateString("fr-CH") + " " + now.toLocaleTimeString("fr-CH", {hour:"2-digit",minute:"2-digit"}),
      lignes: lignes.map(l => ({
        ...l,
        montant: l.quantite * l.prixUnitaire * (1 - l.rabais / 100),
      })),
      totalHT,
    };
    try {
      const res = await fetch("/api/commandes", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
      });
      const commande = await res.json();
      generatePDF(commande);
      setSuccess(commande.numero);
    } catch {
      alert("Erreur lors de la création.");
    } finally {
      setLoading(false);
    }
  }

  async function loadHistorique() {
    const data = await fetch("/api/commandes").then(r => r.json());
    setHistorique(data);
  }

  const f = (k: keyof typeof DEFAULT_FORM) => (e: React.ChangeEvent<HTMLInputElement|HTMLTextAreaElement>) =>
    setForm(prev => ({ ...prev, [k]: e.target.value }));

  return (
    <main className="min-h-screen bg-gray-100">
      <header className="bg-[#003087] text-white py-4 px-6 flex items-center gap-4 shadow-lg">
        <div className="text-3xl font-black tracking-tight">INDUNI</div>
        <div className="w-px h-8 bg-blue-400 mx-2" />
        <div>
          <div className="text-lg font-semibold">Bons de Commande</div>
          <div className="text-blue-300 text-xs">Génération automatique PDF + Outlook</div>
        </div>
      </header>

      <div className="max-w-5xl mx-auto px-4 py-6">
        <div className="flex gap-2 mb-6">
          <button onClick={() => setTab("formulaire")}
            className={`px-5 py-2 rounded-full text-sm font-semibold transition ${tab==="formulaire"?"bg-[#003087] text-white shadow":"bg-white text-gray-600 border hover:border-[#003087]"}`}>
            Nouveau bon
          </button>
          <button onClick={() => { setTab("historique"); loadHistorique(); }}
            className={`px-5 py-2 rounded-full text-sm font-semibold transition ${tab==="historique"?"bg-[#003087] text-white shadow":"bg-white text-gray-600 border hover:border-[#003087]"}`}>
            Historique
          </button>
        </div>

        {tab === "formulaire" && (
          <form onSubmit={handleSubmit} className="space-y-5">
            {success && (
              <div className="bg-green-50 border-l-4 border-green-500 text-green-800 px-5 py-3 rounded-lg flex items-center gap-2">
                <span className="text-xl">✅</span>
                <span>Bon <strong>{success}</strong> créé — PDF téléchargé et Outlook ouvert.</span>
              </div>
            )}

            <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
              <div className="bg-[#003087] text-white px-5 py-3 text-sm font-semibold uppercase tracking-wider">Client / Société</div>
              <div className="p-5 grid grid-cols-1 md:grid-cols-2 gap-4">
                <div><label className="label">Société *</label>
                  <input required className="input" value={form.societe} onChange={f("societe")} /></div>
                <div><label className="label">Adresse de facturation</label>
                  <textarea className="input h-16 resize-none" value={form.adresseSociete} onChange={f("adresseSociete")} /></div>
                <div><label className="label">Responsable (Contact) *</label>
                  <input required className="input" value={form.responsable} onChange={f("responsable")} /></div>
                <div><label className="label">Email responsable *</label>
                  <input required type="email" className="input" value={form.emailResponsable} onChange={f("emailResponsable")} /></div>
                <div><label className="label">Email facturation</label>
                  <input type="email" className="input" value={form.emailFacturation} onChange={f("emailFacturation")} /></div>
              </div>
            </div>

            <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
              <div className="bg-[#003087] text-white px-5 py-3 text-sm font-semibold uppercase tracking-wider">Chantier</div>
              <div className="p-5 grid grid-cols-1 md:grid-cols-2 gap-4">
                <div><label className="label">Nom du chantier *</label>
                  <input required className="input" value={form.nomChantier} onChange={f("nomChantier")} /></div>
                <div><label className="label">N° de chantier *</label>
                  <input required className="input" value={form.codeChantier} onChange={f("codeChantier")} /></div>
                <div><label className="label">Adresse de livraison</label>
                  <textarea className="input h-16 resize-none" value={form.adresseLivraison} onChange={f("adresseLivraison")} /></div>
                <div className="space-y-4">
                  <div><label className="label">Nom contact chantier</label>
                    <input className="input" value={form.nomContactChantier} onChange={f("nomContactChantier")} /></div>
                  <div><label className="label">Numéro contact chantier</label>
                    <input className="input" value={form.numeroContactChantier} onChange={f("numeroContactChantier")} /></div>
                </div>
                <div><label className="label">Technicien</label>
                  <input className="input" value={form.technicien} onChange={f("technicien")} /></div>
                <div><label className="label">Contraintes du chantier</label>
                  <input className="input" value={form.contraintes} onChange={f("contraintes")} /></div>
              </div>
            </div>

            <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
              <div className="bg-[#003087] text-white px-5 py-3 text-sm font-semibold uppercase tracking-wider">Fournisseur</div>
              <div className="p-5 grid grid-cols-1 md:grid-cols-2 gap-4">
                <div><label className="label">Nom du fournisseur *</label>
                  <input required className="input" value={form.fournisseur} onChange={f("fournisseur")} /></div>
                <div><label className="label">Adresse fournisseur</label>
                  <textarea className="input h-16 resize-none" value={form.adresseFournisseur} onChange={f("adresseFournisseur")} /></div>
                <div><label className="label">Email fournisseur *</label>
                  <input required type="email" className="input" value={form.emailFournisseur} onChange={f("emailFournisseur")} /></div>
              </div>
            </div>

            <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
              <div className="bg-[#003087] text-white px-5 py-3 text-sm font-semibold uppercase tracking-wider">Articles commandés</div>
              <div className="p-5">
                <div className="overflow-x-auto">
                  <table className="w-full text-sm">
                    <thead>
                      <tr className="border-b-2 border-[#003087] text-[#003087] text-left">
                        <th className="pb-2 font-semibold">Désignation</th>
                        <th className="pb-2 font-semibold w-28">Date livr.</th>
                        <th className="pb-2 font-semibold w-16">Qté</th>
                        <th className="pb-2 font-semibold w-20">Unité</th>
                        <th className="pb-2 font-semibold w-20">Rabais %</th>
                        <th className="pb-2 font-semibold w-28">Prix CHF</th>
                        <th className="pb-2 font-semibold w-28 text-right">Montant</th>
                        <th className="w-6"></th>
                      </tr>
                    </thead>
                    <tbody>
                      {lignes.map((l, i) => {
                        const montant = l.quantite * l.prixUnitaire * (1 - l.rabais / 100);
                        return (
                          <tr key={i} className="border-b last:border-0 hover:bg-gray-50">
                            <td className="py-2 pr-2"><input required className="input py-1" value={l.designation} onChange={e => updateLigne(i,"designation",e.target.value)} placeholder="Description de l'article" /></td>
                            <td className="py-2 pr-2"><input type="date" className="input py-1 text-xs" value={l.dateLivraison} onChange={e => updateLigne(i,"dateLivraison",e.target.value)} /></td>
                            <td className="py-2 pr-2"><input type="number" min="0" step="0.01" className="input py-1 text-center" value={l.quantite} onChange={e => updateLigne(i,"quantite",parseFloat(e.target.value)||0)} /></td>
                            <td className="py-2 pr-2">
                              <select className="input py-1" value={l.unite} onChange={e => updateLigne(i,"unite",e.target.value)}>
                                <option>u</option><option>pcs</option><option>kg</option><option>to</option><option>m</option><option>m²</option><option>m³</option><option>L</option><option>h</option><option>forfait</option>
                              </select>
                            </td>
                            <td className="py-2 pr-2"><input type="number" min="0" max="100" step="0.1" className="input py-1 text-center" value={l.rabais} onChange={e => updateLigne(i,"rabais",parseFloat(e.target.value)||0)} /></td>
                            <td className="py-2 pr-2"><input type="number" min="0" step="0.01" className="input py-1 text-right" value={l.prixUnitaire} onChange={e => updateLigne(i,"prixUnitaire",parseFloat(e.target.value)||0)} /></td>
                            <td className="py-2 pr-2 font-semibold text-right text-gray-700">{montant.toFixed(2)}</td>
                            <td>{lignes.length>1 && <button type="button" onClick={()=>setLignes(p=>p.filter((_,j)=>j!==i))} className="text-red-400 hover:text-red-600 text-lg font-bold">×</button>}</td>
                          </tr>
                        );
                      })}
                    </tbody>
                  </table>
                </div>
                <button type="button" onClick={()=>setLignes(p=>[...p,{designation:"",dateLivraison:"",quantite:1,unite:"u",rabais:0,prixUnitaire:0}])}
                  className="mt-3 text-sm text-[#003087] font-semibold hover:underline">+ Ajouter une ligne</button>
                <div className="mt-4 flex justify-end">
                  <div className="w-64 border-t-2 border-[#003087] pt-3">
                    <div className="flex justify-between font-bold text-lg text-[#003087]">
                      <span>Total HT</span><span>{totalHT.toFixed(2)} CHF</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
              <div className="bg-gray-100 px-5 py-3 text-sm font-semibold text-gray-600 uppercase tracking-wider">Notes complémentaires</div>
              <div className="p-5">
                <textarea className="input h-20 resize-none" placeholder="Informations complémentaires..." value={form.notes} onChange={f("notes")} />
              </div>
            </div>

            <button type="submit" disabled={loading}
              className="w-full bg-[#003087] text-white py-4 rounded-xl font-bold hover:bg-blue-900 disabled:opacity-50 text-base shadow-lg transition">
              {loading ? "Génération en cours..." : "📄 Générer le bon de commande (PDF + Outlook)"}
            </button>
          </form>
        )}

        {tab === "historique" && (
          <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
            {historique.length === 0 ? (
              <div className="p-12 text-center text-gray-400">Aucun bon de commande enregistré.</div>
            ) : (
              <table className="w-full text-sm">
                <thead className="bg-[#003087] text-white">
                  <tr>
                    <th className="text-left px-4 py-3 font-medium">Numéro</th>
                    <th className="text-left px-4 py-3 font-medium">Date</th>
                    <th className="text-left px-4 py-3 font-medium">Chantier</th>
                    <th className="text-left px-4 py-3 font-medium">Fournisseur</th>
                    <th className="text-right px-4 py-3 font-medium">Total HT</th>
                    <th className="px-4 py-3"></th>
                  </tr>
                </thead>
                <tbody>
                  {historique.map((c,i) => (
                    <tr key={c.id} className={`border-b hover:bg-blue-50 ${i%2===0?"bg-white":"bg-gray-50"}`}>
                      <td className="px-4 py-3 font-mono font-bold text-[#003087]">{c.numero}</td>
                      <td className="px-4 py-3 text-gray-600">{c.date}</td>
                      <td className="px-4 py-3">{c.nomChantier} <span className="text-gray-400 text-xs">{c.codeChantier}</span></td>
                      <td className="px-4 py-3">{c.fournisseur}</td>
                      <td className="px-4 py-3 text-right font-bold">{Number(c.totalHT).toFixed(2)} CHF</td>
                      <td className="px-4 py-3"><button onClick={()=>generatePDF(c)} className="text-[#003087] hover:underline text-xs font-semibold">PDF</button></td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>
        )}
      </div>
    </main>
  );
}