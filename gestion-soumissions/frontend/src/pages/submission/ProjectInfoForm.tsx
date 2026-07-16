import { useState } from "react";
import { api } from "../../api/client";
import type { Submission } from "../../api/types";

type Props = { submission: Submission; onChanged: () => void };

export function ProjectInfoForm({ submission, onChanged }: Props) {
  const [open, setOpen] = useState(false);

  const update = async (data: Partial<Submission>) => {
    await api.patch(`/submissions/${submission.id}`, data);
    onChanged();
  };

  return (
    <div className="card project-info">
      <button className="disclosure" onClick={() => setOpen((o) => !o)}>
        {open ? "▾" : "▸"} Informations de la soumission
      </button>
      {open && (
        <div className="form-grid">
          <label>
            Nom du projet
            <input defaultValue={submission.name} onBlur={(e) => update({ name: e.target.value })} />
          </label>
          <label>
            Référence
            <input defaultValue={submission.ref ?? ""} onBlur={(e) => update({ ref: e.target.value })} />
          </label>
          <label>
            Lieu
            <input defaultValue={submission.lieu ?? ""} onBlur={(e) => update({ lieu: e.target.value })} />
          </label>
          <label>
            Entité
            <input defaultValue={submission.entite ?? ""} onBlur={(e) => update({ entite: e.target.value })} />
          </label>
          <label>
            Contact — nom
            <input defaultValue={submission.contactName ?? ""} onBlur={(e) => update({ contactName: e.target.value })} />
          </label>
          <label>
            Contact — e-mail
            <input
              type="email"
              defaultValue={submission.contactEmail ?? ""}
              onBlur={(e) => update({ contactEmail: e.target.value })}
            />
          </label>
          <label>
            Date limite de retour
            <input
              type="date"
              defaultValue={submission.dateLimiteRetour?.slice(0, 10) ?? ""}
              onChange={(e) => update({ dateLimiteRetour: e.target.value || undefined })}
            />
          </label>
          <label>
            Lien vers les documents
            <input defaultValue={submission.lienDocument ?? ""} onBlur={(e) => update({ lienDocument: e.target.value })} />
          </label>
        </div>
      )}
    </div>
  );
}
