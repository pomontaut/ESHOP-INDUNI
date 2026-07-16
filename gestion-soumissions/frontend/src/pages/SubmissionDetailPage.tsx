import { useCallback, useEffect, useState } from "react";
import { Link, useParams } from "react-router-dom";
import { api } from "../api/client";
import type { Submission } from "../api/types";
import { ProjectInfoForm } from "./submission/ProjectInfoForm";
import { ExtractionTab } from "./submission/ExtractionTab";
import { LotsTab } from "./submission/LotsTab";
import { SuiviTab } from "./submission/SuiviTab";
import { AnnexeTab } from "./submission/AnnexeTab";

const TABS = [
  { key: "extraction", label: "1. Extraction de la soumission" },
  { key: "lots", label: "2. Lots & e-mails" },
  { key: "suivi", label: "3. Dashboard de suivi" },
  { key: "annexe", label: "4. Annexe — Méthode de détection" },
] as const;

type TabKey = (typeof TABS)[number]["key"];

export function SubmissionDetailPage() {
  const { id } = useParams<{ id: string }>();
  const [submission, setSubmission] = useState<Submission | null>(null);
  const [tab, setTab] = useState<TabKey>("extraction");

  const load = useCallback(() => {
    if (!id) return;
    api.get<Submission>(`/submissions/${id}`).then(setSubmission);
  }, [id]);

  useEffect(load, [load]);

  if (!submission) return <div className="page-loading">Chargement…</div>;

  return (
    <div className="page">
      <header className="page-header">
        <div>
          <Link to="/" className="back-link">
            ← Mes soumissions
          </Link>
          <h1>{submission.name}</h1>
          {submission.ref && <p>Réf. {submission.ref}</p>}
        </div>
      </header>

      <ProjectInfoForm submission={submission} onChanged={load} />

      <div className="tabs">
        {TABS.map((t) => (
          <button key={t.key} className={`tab ${tab === t.key ? "active" : ""}`} onClick={() => setTab(t.key)}>
            {t.label}
          </button>
        ))}
      </div>

      {tab === "extraction" && <ExtractionTab submission={submission} onChanged={load} />}
      {tab === "lots" && <LotsTab submission={submission} onChanged={load} />}
      {tab === "suivi" && <SuiviTab submission={submission} onChanged={load} />}
      {tab === "annexe" && <AnnexeTab />}
    </div>
  );
}
