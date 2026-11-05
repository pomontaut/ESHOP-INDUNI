#!/usr/bin/env python3
"""Associe chaque article Canplast à l'image de sa famille dans le catalogue de commande canplast.ch
(canplast.ch/catalogue/fr/categories/N : une image par famille d'articles, ex. LDT.png = tuyaux PVC compact,
rattachée à la référence du tableau). Les images sont des illustrations de famille, pas des photos par article.
Usage : fetch_canplast_media.py <catalog_products.json> <dossier_images>
Met à jour `image` des articles Canplast SANS image (jamais ceux qui en ont déjà une)."""
import json, os, re, sys, time, urllib.request
CAT, DEST = sys.argv[1:3]
UA = {"User-Agent": "Mozilla/5.0 (Induni catalogue sync)"}
def get(u):
    with urllib.request.urlopen(urllib.request.Request(u, headers=UA), timeout=40) as r: return r.read()
os.makedirs(DEST, exist_ok=True)
home = get("https://canplast.ch/catalogue/fr").decode("utf8", "replace")
cats = sorted(set(re.findall(r'catalogue/fr/categories/([0-9.]+)', home)))
rows = {}
for c in cats:
    h = get("https://canplast.ch/catalogue/fr/categories/" + c).decode("utf8", "replace")
    for m in re.finditer(r'<img src="https://canplast.ch/catalogue/img/([^"]+)"[^>]*>\s*</td>\s*<td>([^<]+)</td>', h):
        rows[m.group(2).strip()] = m.group(1)
    time.sleep(0.3)
files = {}
for img in sorted(set(rows.values())):
    fn = "canplast-" + img.lower()
    p = os.path.join(DEST, fn)
    if not os.path.exists(p):
        open(p, "wb").write(get("https://canplast.ch/catalogue/img/" + img)); time.sleep(0.2)
    files[img] = fn
data = json.load(open(CAT, encoding="utf-8"))
n = 0
for it in data:
    if it["catalog"] == "Canplast" and not it.get("image") and it["article"] in rows:
        it["image"] = "/images/products/" + files[rows[it["article"]]]; n += 1
json.dump(data, open(CAT, "w", encoding="utf-8"), ensure_ascii=False)
print("articles mis à jour:", n, "images:", len(files))
