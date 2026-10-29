#!/usr/bin/env python3
"""Reconstitue, jour après jour, les indicateurs de construction de l'e-shop depuis l'historique git.

Usage : python3 script/build_eshop_metrics_history.py [date_debut=2026-10-01] [sortie.json] [branche=origin/main]

Pour chaque jour, prend le dernier commit de la branche daté de ce jour (ou antérieur) et lit
db/seed_data/catalog_products.json (+ nomenclature_induni.json quand il existe) tel qu'il était alors :
- references  : articles avec une famille (hors articles sortis du catalogue) ;
- equivalent  : articles dont la clé d'équivalence est partagée par au moins 2 catalogues fournisseurs ;
- induni      : articles du catalogue ayant une ligne de nomenclature INDUNI (n° + désignation) ;
- catalogs    : catalogues fournisseurs distincts ;
- photos      : articles avec une photo (champ image renseigné).
Nécessite l'historique complet (git fetch --unshallow). Les jours suivants sont mesurés en direct par l'e-shop
(EshopMetric.snapshot!).
"""
import datetime, json, subprocess, sys, collections

start = datetime.date.fromisoformat(sys.argv[1]) if len(sys.argv) > 1 else datetime.date(2026, 10, 1)
dst = sys.argv[2] if len(sys.argv) > 2 else "db/seed_data/eshop_metrics_history.json"
branch = sys.argv[3] if len(sys.argv) > 3 else "origin/main"

def git(*a):
    return subprocess.run(["git", *a], capture_output=True, text=True, check=True).stdout

def show(commit, path):
    r = subprocess.run(["git", "show", f"{commit}:{path}"], capture_output=True, text=True)
    return json.loads(r.stdout) if r.returncode == 0 and r.stdout.strip() else None

commits = [l.split() for l in git("log", "--first-parent", "--format=%H %cs", branch).splitlines()]
by_day = {}
for h, day in commits:
    by_day.setdefault(day, h)          # plus récent d'abord : on garde le dernier commit du jour
days = sorted(by_day)
cache = {}
def metrics(commit):
    if commit in cache: return cache[commit]
    cat = show(commit, "db/seed_data/catalog_products.json") or []
    nom = show(commit, "db/seed_data/nomenclature_induni.json") or []
    items = [p for p in cat if p.get("famille")]
    keys = collections.defaultdict(set)
    for p in items:
        if p.get("equivalenceKey"): keys[p["equivalenceKey"]].add(p["catalog"])
    shared = {k for k, v in keys.items() if len(v) >= 2}
    refs = {(p["catalog"], str(p["article"])) for p in items}
    induni = {(n["supplierName"], str(n["supplierReference"])) for n in nom if n.get("induniReference") and n.get("induniDesignation")} & refs
    cache[commit] = {
        "references": len(items),
        "equivalent": sum(1 for p in items if p.get("equivalenceKey") in shared),
        "induni": len(induni),
        "catalogs": len({p["catalog"] for p in items}),
        "photos": sum(1 for p in items if p.get("image")),
    }
    return cache[commit]

out = []
day = start
today = datetime.date.today()
last = None
while day <= today:
    ds = day.isoformat()
    cands = [d for d in days if d <= ds]
    if cands:
        out.append({"date": ds, **metrics(by_day[cands[-1]]), "source": "git"})
    day += datetime.timedelta(days=1)
with open(dst, "w", encoding="utf-8") as f:
    json.dump(out, f, ensure_ascii=False, indent=1); f.write("\n")
print(f"{len(out)} jours -> {dst}")
print(out[0], out[-1], sep="\n")
