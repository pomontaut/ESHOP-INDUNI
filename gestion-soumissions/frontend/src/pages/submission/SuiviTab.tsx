import { api } from "../../api/client";
import type { Submission, SuiviRow } from "../../api/types";
import { SUIVI_STATUS_OPTS } from "../../api/types";

type Props = { submission: Submission; onChanged: () => void };

export function SuiviTab({ submission, onChanged }: Props) {
  const lots = submission.lots ?? [];
  const totalRows = lots.reduce((acc, l) => acc + l.suivi.length, 0);
  const retainedAmount = lots.reduce((acc, l) => {
    const retained = l.suivi.find((r) => r.retained);
    return acc + (retained?.montant ?? 0);
  }, 0);

  const update = async (row: SuiviRow, data: Partial<SuiviRow>) => {
    await api.patch(`/suivi/${row.id}`, data);
    onChanged();
  };

  const retain = async (row: SuiviRow) => {
    await api.patch(`/suivi/${row.id}/retain`, {});
    onChanged();
  };

  const remove = async (row: SuiviRow) => {
    if (!confirm("Retirer cette ligne du suivi ?")) return;
    await api.delete(`/suivi/${row.id}`);
    onChanged();
  };

  const relance = async (row: SuiviRow) => {
    const content = await api.get<{ to: string | null; subject: string; body: string; nextStatus: string }>(
      `/suivi/${row.id}/relance-email`,
    );
    window.location.href = `mailto:${encodeURIComponent(content.to ?? "")}?subject=${encodeURIComponent(
      content.subject,
    )}&body=${encodeURIComponent(content.body)}`;
    await update(row, { status: content.nextStatus, relanceDate: new Date().toISOString() });
  };

  return (
    <div className="tab-content">
      <div className="card suivi-summary">
        <h2>3. Dashboard de suivi</h2>
        <div className="stat-row">
          <div className="stat">
            <span className="stat-value">{lots.length}</span>
            <span className="stat-label">Lots</span>
          </div>
          <div className="stat">
            <span className="stat-value">{totalRows}</span>
            <span className="stat-label">Fournisseurs consultés</span>
          </div>
          <div className="stat">
            <span className="stat-value">{retainedAmount.toLocaleString("fr-CH")} CHF</span>
            <span className="stat-label">Total retenu</span>
          </div>
        </div>
        <a className="btn ghost" href={`/api/submissions/${submission.id}/suivi/export.csv`} target="_blank" rel="noreferrer">
          ⬇ Export CSV
        </a>
      </div>

      {lots.map((lot) => (
        <div className="card" key={lot.id}>
          <h3>
            {lot.cfcRef ? `CFC ${lot.cfcRef} — ` : ""}
            {lot.title}
          </h3>
          {lot.suivi.length === 0 ? (
            <p className="empty">Aucun fournisseur consulté pour ce lot pour l'instant.</p>
          ) : (
            <div className="table-scroll">
              <table className="suivi-table">
                <thead>
                  <tr>
                    <th>Fournisseur</th>
                    <th>Statut</th>
                    <th>Date relance</th>
                    <th></th>
                    <th>Montant estim.</th>
                    <th>Montant</th>
                    <th>Conforme</th>
                    <th>Date retour</th>
                    <th>Notes</th>
                    <th>Retenu</th>
                    <th></th>
                  </tr>
                </thead>
                <tbody>
                  {lot.suivi.map((row) => {
                    const supplier = lot.suppliers.find((s) => s.id === row.lotSupplierId);
                    return (
                      <tr key={row.id}>
                        <td>{supplier?.supplierName ?? "—"}</td>
                        <td>
                          <select value={row.status} onChange={(e) => update(row, { status: e.target.value })}>
                            {SUIVI_STATUS_OPTS.map(([v, l]) => (
                              <option key={v} value={v}>
                                {l}
                              </option>
                            ))}
                          </select>
                        </td>
                        <td>
                          <input
                            type="date"
                            value={row.relanceDate?.slice(0, 10) ?? ""}
                            onChange={(e) => update(row, { relanceDate: e.target.value || null })}
                          />
                        </td>
                        <td>
                          {row.status !== "Decline" && (
                            <button className="btn ghost small" onClick={() => relance(row)}>
                              ✉ Relancer
                            </button>
                          )}
                        </td>
                        <td>
                          <input
                            defaultValue={row.montantEstimatif ?? ""}
                            placeholder="CHF (estim.)"
                            onBlur={(e) => update(row, { montantEstimatif: e.target.value ? Number(e.target.value) : null })}
                          />
                        </td>
                        <td>
                          <input
                            defaultValue={row.montant ?? ""}
                            placeholder="CHF"
                            onBlur={(e) => update(row, { montant: e.target.value ? Number(e.target.value) : null })}
                          />
                        </td>
                        <td style={{ textAlign: "center" }}>
                          <input
                            type="checkbox"
                            checked={row.conforme}
                            onChange={(e) => update(row, { conforme: e.target.checked })}
                          />
                        </td>
                        <td>
                          <input
                            type="date"
                            value={row.dateRetour?.slice(0, 10) ?? ""}
                            onChange={(e) => update(row, { dateRetour: e.target.value || null })}
                          />
                        </td>
                        <td>
                          <input defaultValue={row.notes ?? ""} onBlur={(e) => update(row, { notes: e.target.value })} />
                        </td>
                        <td style={{ textAlign: "center" }}>
                          <input
                            type="radio"
                            name={`retenu-${lot.id}`}
                            checked={row.retained}
                            onChange={() => retain(row)}
                          />
                        </td>
                        <td>
                          <button className="btn danger small" onClick={() => remove(row)}>
                            ✕
                          </button>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          )}
        </div>
      ))}
    </div>
  );
}
