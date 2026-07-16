import { useState } from "react";
import { api } from "../../api/client";
import type { Lot, Submission } from "../../api/types";
import { LotEmailPanel } from "./LotEmailPanel";
import { SourcingPicker } from "./SourcingPicker";

type Props = { submission: Submission; onChanged: () => void };

export function LotsTab({ submission, onChanged }: Props) {
  const lots = submission.lots ?? [];
  const [selectedLotId, setSelectedLotId] = useState<string | null>(lots[0]?.id ?? null);
  const selectedLot = lots.find((l) => l.id === selectedLotId) ?? null;

  const updateLot = async (id: string, data: Partial<Pick<Lot, "title" | "cfcRef" | "workType" | "status">>) => {
    await api.patch(`/lots/${id}`, data);
    onChanged();
  };

  const deleteLot = async (id: string) => {
    if (!confirm("Supprimer ce lot ?")) return;
    await api.delete(`/lots/${id}`);
    if (selectedLotId === id) setSelectedLotId(null);
    onChanged();
  };

  const setSupplierStatus = async (lotSupplierId: string, status: "validated" | "dismissed") => {
    await api.patch(`/lot-suppliers/${lotSupplierId}`, { status });
    onChanged();
  };

  const toggleSelectedForEmail = async (lotSupplierId: string, selectedForEmail: boolean) => {
    await api.patch(`/lot-suppliers/${lotSupplierId}`, { selectedForEmail });
    onChanged();
  };

  const removeSupplier = async (lotSupplierId: string) => {
    await api.delete(`/lot-suppliers/${lotSupplierId}`);
    onChanged();
  };

  const addToSuivi = async (lotId: string, lotSupplierId: string) => {
    await api.post(`/lots/${lotId}/suivi`, { lotSupplierId });
    onChanged();
  };

  return (
    <div className="tab-content lots-layout">
      <aside className="lots-sidebar">
        <h2>Lots ({lots.length})</h2>
        {lots.length === 0 && <div className="empty">Aucun lot. Créez-en un dans l'onglet Extraction.</div>}
        <ul className="lots-list">
          {lots.map((l) => (
            <li key={l.id}>
              <button
                className={`lot-list-item ${l.id === selectedLotId ? "active" : ""}`}
                onClick={() => setSelectedLotId(l.id)}
              >
                <span className="lot-title">
                  {l.cfcRef ? `CFC ${l.cfcRef} — ` : ""}
                  {l.title}
                </span>
                <span className={`status-pill ${l.status}`}>{l.status === "validated" ? "Validé" : "Proposé"}</span>
              </button>
            </li>
          ))}
        </ul>
      </aside>

      <section className="lot-detail">
        {!selectedLot ? (
          <div className="empty">Sélectionnez un lot.</div>
        ) : (
          <div className="card">
            <div className="form-grid">
              <label>
                Titre
                <input
                  defaultValue={selectedLot.title}
                  onBlur={(e) => e.target.value !== selectedLot.title && updateLot(selectedLot.id, { title: e.target.value })}
                />
              </label>
              <label>
                Référence CFC
                <input
                  defaultValue={selectedLot.cfcRef ?? ""}
                  onBlur={(e) => updateLot(selectedLot.id, { cfcRef: e.target.value })}
                />
              </label>
              <label>
                Type de travaux
                <input
                  defaultValue={selectedLot.workType ?? ""}
                  onBlur={(e) => updateLot(selectedLot.id, { workType: e.target.value })}
                />
              </label>
            </div>
            <div className="lot-actions">
              {selectedLot.status === "proposed" ? (
                <button onClick={() => updateLot(selectedLot.id, { status: "validated" })}>✓ Valider le lot</button>
              ) : (
                <button className="btn ghost" onClick={() => updateLot(selectedLot.id, { status: "proposed" })}>
                  Dévalider
                </button>
              )}
              <button className="btn danger" onClick={() => deleteLot(selectedLot.id)}>
                Supprimer le lot
              </button>
            </div>

            <h3>Fournisseurs proposés — à valider</h3>
            {selectedLot.suppliers.filter((s) => s.status === "suggested").length === 0 ? (
              <p className="muted">Aucune suggestion en attente.</p>
            ) : (
              <ul className="supplier-list">
                {selectedLot.suppliers
                  .filter((s) => s.status === "suggested")
                  .map((s) => (
                    <li key={s.id}>
                      <span>
                        {s.supplierName} {s.email && <span className="muted">— {s.email}</span>}
                      </span>
                      <div className="row-actions">
                        <button className="btn small" onClick={() => setSupplierStatus(s.id, "validated")}>
                          ✓ Valider
                        </button>
                        <button className="btn ghost small" onClick={() => setSupplierStatus(s.id, "dismissed")}>
                          Ignorer
                        </button>
                      </div>
                    </li>
                  ))}
              </ul>
            )}

            <h3>Fournisseurs validés pour ce lot</h3>
            {selectedLot.suppliers.filter((s) => s.status === "validated").length === 0 ? (
              <p className="muted">Aucun fournisseur validé pour l'instant.</p>
            ) : (
              <ul className="supplier-list">
                {selectedLot.suppliers
                  .filter((s) => s.status === "validated")
                  .map((s) => (
                    <li key={s.id}>
                      <label className="checkbox-label">
                        <input
                          type="checkbox"
                          checked={s.selectedForEmail}
                          onChange={(e) => toggleSelectedForEmail(s.id, e.target.checked)}
                        />
                        {s.supplierName} {s.email && <span className="muted">— {s.email}</span>}
                      </label>
                      <div className="row-actions">
                        <button
                          className="btn ghost small"
                          onClick={() => addToSuivi(selectedLot.id, s.id)}
                          title="Ajouter au suivi"
                        >
                          → Suivi
                        </button>
                        <button className="btn danger small" onClick={() => removeSupplier(s.id)}>
                          ✕
                        </button>
                      </div>
                    </li>
                  ))}
              </ul>
            )}

            <SourcingPicker lotId={selectedLot.id} onAdded={onChanged} />

            <LotEmailPanel lot={selectedLot} />
          </div>
        )}
      </section>
    </div>
  );
}
