import { useEffect, useState } from "react";
import type { FormEvent } from "react";
import { Link, useNavigate } from "react-router-dom";
import { api } from "../api/client";
import type { Submission } from "../api/types";
import { useAuth } from "../context/AuthContext";

export function SubmissionsListPage() {
  const { user, logout } = useAuth();
  const navigate = useNavigate();
  const [submissions, setSubmissions] = useState<Submission[]>([]);
  const [loading, setLoading] = useState(true);
  const [newName, setNewName] = useState("");
  const [newRef, setNewRef] = useState("");
  const [creating, setCreating] = useState(false);

  const load = () => {
    setLoading(true);
    api
      .get<Submission[]>("/submissions")
      .then(setSubmissions)
      .finally(() => setLoading(false));
  };

  useEffect(load, []);

  const onCreate = async (e: FormEvent) => {
    e.preventDefault();
    if (!newName.trim()) return;
    setCreating(true);
    try {
      const submission = await api.post<Submission>("/submissions", { name: newName, ref: newRef || undefined });
      setNewName("");
      setNewRef("");
      navigate(`/soumissions/${submission.id}`);
    } finally {
      setCreating(false);
    }
  };

  const onDelete = async (id: string, e: React.MouseEvent) => {
    e.preventDefault();
    e.stopPropagation();
    if (!confirm("Supprimer définitivement cette soumission et tous ses lots ?")) return;
    await api.delete(`/submissions/${id}`);
    load();
  };

  return (
    <div className="page">
      <header className="page-header">
        <div>
          <h1>🗂 Mes soumissions</h1>
          <p>Gestion des soumissions — Induni</p>
        </div>
        <div className="header-actions">
          <span className="user-badge">{user?.name}</span>
          <button className="btn ghost" onClick={() => logout()}>
            Déconnexion
          </button>
        </div>
      </header>

      <form className="card create-submission" onSubmit={onCreate}>
        <h2>Nouvelle soumission</h2>
        <div className="form-row">
          <input
            placeholder="Nom du projet"
            value={newName}
            onChange={(e) => setNewName(e.target.value)}
            required
          />
          <input placeholder="Référence (optionnel)" value={newRef} onChange={(e) => setNewRef(e.target.value)} />
          <button type="submit" disabled={creating}>
            {creating ? "Création…" : "+ Créer"}
          </button>
        </div>
      </form>

      {loading ? (
        <div className="empty">Chargement…</div>
      ) : submissions.length === 0 ? (
        <div className="empty">Aucune soumission pour l'instant.</div>
      ) : (
        <div className="submission-grid">
          {submissions.map((s) => (
            <Link to={`/soumissions/${s.id}`} className="card submission-card" key={s.id}>
              <div className="submission-card-head">
                <h3>{s.name}</h3>
                <button className="btn danger small" onClick={(e) => onDelete(s.id, e)}>
                  ✕
                </button>
              </div>
              {s.ref && <p className="muted">Réf. {s.ref}</p>}
              <p className="muted">{s._count?.lots ?? 0} lot(s)</p>
              <p className="muted small">Par {s.owner?.name}</p>
            </Link>
          ))}
        </div>
      )}
    </div>
  );
}
