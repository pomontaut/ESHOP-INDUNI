#!/usr/bin/env python3
"""Construit db/seed_data/soumission_history.json.gz (mémoire « historique soumissions BAT GE »)
depuis le classeur « Articles des soumissions PDF 2010-2026 » (onglet Articles).
Ne garde que les lignes « fourniture et pose » (colonne L renseignée : « article » ou « titre au-dessus »),
regroupées par (texte normalisé, unité). Aucun prix (PU quasi vide dans la source : non repris).
Usage : python3 script/build_soumission_history.py <classeur.xlsx> [sortie.json.gz]"""
import sys, gzip, json, re, unicodedata, statistics, collections
import openpyxl

def norm(s):
    s = unicodedata.normalize("NFD", str(s or "").lower())
    s = "".join(c for c in s if unicodedata.category(c) != "Mn")
    return re.sub(r"[^a-z0-9]+", " ", s).strip()

src = sys.argv[1]
out = sys.argv[2] if len(sys.argv) > 2 else "db/seed_data/soumission_history.json.gz"
ws = openpyxl.load_workbook(src, read_only=True)["Articles"]
groups = collections.OrderedDict()
for r in ws.iter_rows(min_row=3, values_only=True):
    year, affaire, doc, page, code, text, titre, unit, qty, pu, lot, fp, ident = r[:13]
    if not fp or not (text and str(text).strip()):
        continue
    key = (norm(text), str(unit or "").strip().lower())
    if not key[0]:
        continue
    g = groups.setdefault(key, {"t": str(text).strip()[:400], "c": str(code or ""), "u": key[1], "h": str(titre or "")[:160],
                                "s": "article" if fp == "article" else "titre", "years": [], "aff": [], "q": []})
    if fp == "article":
        g["s"] = "article"
    g["years"].append(int(year)); g["aff"].append(str(affaire or ""))
    try:
        g["q"].append(float(qty))
    except (TypeError, ValueError):
        pass
rows = []
for g in groups.values():
    aff = collections.Counter(g["aff"])
    rows.append({"t": g["t"], "c": g["c"], "u": g["u"], "h": g["h"], "s": g["s"], "n": len(g["years"]),
                 "y0": min(g["years"]), "y1": max(g["years"]), "na": len(aff), "a": aff.most_common(1)[0][0][:80],
                 "q": round(statistics.median(g["q"]), 2) if g["q"] else None})
with gzip.open(out, "wt", encoding="utf-8", compresslevel=9) as f:
    json.dump(rows, f, ensure_ascii=False, separators=(",", ":"))
print(len(rows), "entrées ->", out)
