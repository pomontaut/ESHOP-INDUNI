import { useState } from "react";
import { api } from "../../api/client";
import type { Lot } from "../../api/types";

type EmailContent = { to: string[]; subject: string; body: string };

export function LotEmailPanel({ lot }: { lot: Lot }) {
  const [email, setEmail] = useState<EmailContent | null>(null);
  const [loading, setLoading] = useState(false);

  const selectedCount = lot.suppliers.filter((s) => s.selectedForEmail).length;

  const generate = async () => {
    setLoading(true);
    try {
      const content = await api.get<EmailContent>(`/lots/${lot.id}/email`);
      setEmail(content);
    } finally {
      setLoading(false);
    }
  };

  const mailtoHref = email
    ? `mailto:${encodeURIComponent(email.to.join(","))}?subject=${encodeURIComponent(email.subject)}&body=${encodeURIComponent(email.body)}`
    : undefined;

  return (
    <div className="email-panel">
      <h3>E-mail de demande de prix</h3>
      <p className="muted">{selectedCount} fournisseur(s) sélectionné(s) pour l'envoi.</p>
      <button onClick={generate} disabled={loading || selectedCount === 0}>
        {loading ? "Génération…" : "Générer l'e-mail"}
      </button>
      {email && (
        <div className="email-preview">
          <label>
            Destinataires
            <input value={email.to.join(", ")} readOnly />
          </label>
          <label>
            Sujet
            <input value={email.subject} readOnly />
          </label>
          <label>
            Corps du message
            <textarea rows={12} value={email.body} readOnly />
          </label>
          <a className="btn" href={mailtoHref}>
            ✉ Ouvrir dans le client mail
          </a>
        </div>
      )}
    </div>
  );
}
