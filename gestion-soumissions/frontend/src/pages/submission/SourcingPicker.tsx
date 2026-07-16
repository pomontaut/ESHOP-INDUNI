import { useEffect, useState } from "react";
import type { FormEvent } from "react";
import { api } from "../../api/client";
import type { SourcingSupplier } from "../../api/types";

type Props = { lotId: string; onAdded: () => void };

export function SourcingPicker({ lotId, onAdded }: Props) {
  const [categories, setCategories] = useState<string[]>([]);
  const [category, setCategory] = useState("");
  const [results, setResults] = useState<SourcingSupplier[]>([]);
  const [customName, setCustomName] = useState("");
  const [customEmail, setCustomEmail] = useState("");

  useEffect(() => {
    api.get<string[]>("/sourcing/categories").then(setCategories);
  }, []);

  useEffect(() => {
    if (!category) {
      setResults([]);
      return;
    }
    api.get<SourcingSupplier[]>(`/sourcing?category=${encodeURIComponent(category)}`).then(setResults);
  }, [category]);

  const addSupplier = async (s: SourcingSupplier) => {
    await api.post(`/lots/${lotId}/suppliers`, {
      sourcingSupplierId: s.id,
      supplierName: s.supplierName,
      email: s.email ?? undefined,
    });
    onAdded();
  };

  const addCustom = async (e: FormEvent) => {
    e.preventDefault();
    if (!customName.trim()) return;
    await api.post(`/lots/${lotId}/suppliers`, {
      supplierName: customName,
      email: customEmail || undefined,
    });
    setCustomName("");
    setCustomEmail("");
    onAdded();
  };

  return (
    <div className="sourcing-picker">
      <h3>Parcourir les fournisseurs par catégorie</h3>
      <select value={category} onChange={(e) => setCategory(e.target.value)}>
        <option value="">— Choisir une catégorie —</option>
        {categories.map((c) => (
          <option key={c} value={c}>
            {c}
          </option>
        ))}
      </select>
      {results.length > 0 && (
        <ul className="supplier-list">
          {results.map((s) => (
            <li key={s.id}>
              <span>
                {s.supplierName} {s.email && <span className="muted">— {s.email}</span>}
              </span>
              <button className="btn small" onClick={() => addSupplier(s)}>
                + Ajouter au lot
              </button>
            </li>
          ))}
        </ul>
      )}

      <h3>Ajouter un nouveau fournisseur</h3>
      <form className="form-row" onSubmit={addCustom}>
        <input placeholder="Nom du fournisseur" value={customName} onChange={(e) => setCustomName(e.target.value)} />
        <input
          placeholder="E-mail (optionnel)"
          value={customEmail}
          onChange={(e) => setCustomEmail(e.target.value)}
        />
        <button type="submit">+ Ajouter</button>
      </form>
    </div>
  );
}
