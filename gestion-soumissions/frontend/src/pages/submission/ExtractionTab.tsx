import { useState } from "react";
import type { FormEvent } from "react";
import { api } from "../../api/client";
import type { Submission } from "../../api/types";

type Props = { submission: Submission; onChanged: () => void };

// L'extraction PDF automatique (détection de zones surlignées, titres de chapitres CFC, etc.)
// n'est pas encore portée depuis le prototype — voir le plan pour la phase 2.
// En attendant, les lots se créent manuellement ci-dessous ou dans l'onglet "Lots & e-mails".
export function ExtractionTab({ submission, onChanged }: Props) {
  const [title, setTitle] = useState("");
  const [cfcRef, setCfcRef] = useState("");
  const [categories, setCategories] = useState("");
  const [creating, setCreating] = useState(false);

  const onCreate = async (e: FormEvent) => {
    e.preventDefault();
    if (!title.trim()) return;
    setCreating(true);
    try {
      await api.post(`/submissions/${submission.id}/lots`, {
        title,
        cfcRef: cfcRef || undefined,
        categories: categories
          .split(",")
          .map((c) => c.trim())
          .filter(Boolean),
      });
      setTitle("");
      setCfcRef("");
      setCategories("");
      onChanged();
    } finally {
      setCreating(false);
    }
  };

  return (
    <div className="tab-content">
      <div className="card notice">
        <strong>Extraction automatique du PDF de soumission — bientôt disponible.</strong>
        <p>
          Dans le prototype, cette étape analyse le PDF de la soumission (texte, zones surlignées, titres de
          chapitres CFC) pour proposer automatiquement des lots. Cette version web pose d'abord les fondations ;
          l'extraction automatique sera portée dans une prochaine itération. En attendant, créez vos lots
          manuellement ci-dessous.
        </p>
      </div>

      <form className="card" onSubmit={onCreate}>
        <h2>Créer un lot manuellement</h2>
        <div className="form-grid">
          <label>
            Titre du lot
            <input value={title} onChange={(e) => setTitle(e.target.value)} required />
          </label>
          <label>
            Référence CFC
            <input value={cfcRef} onChange={(e) => setCfcRef(e.target.value)} placeholder="ex. 213.1" />
          </label>
          <label>
            Catégories de sourcing (séparées par des virgules)
            <input
              value={categories}
              onChange={(e) => setCategories(e.target.value)}
              placeholder="ex. ACIER INOXYDABLE, ANTI GRAFFITI"
            />
          </label>
        </div>
        <button type="submit" disabled={creating}>
          {creating ? "Création…" : "+ Créer le lot"}
        </button>
      </form>
    </div>
  );
}
