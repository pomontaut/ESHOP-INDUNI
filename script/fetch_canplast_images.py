#!/usr/bin/env python3
"""Photos des articles Canplast, prises dans le catalogue en ligne de Canplast
(https://canplast.ch/catalogue/fr/search : une photo par ligne d'article, rattachée
à la référence). N'écrit que les articles SANS image.
Usage : python3 script/fetch_canplast_images.py db/seed_data/catalog_products.json public/images/products
"""
import json, re, sys, os, urllib.request

BASE = "https://canplast.ch/catalogue"
cat, dest = sys.argv[1], sys.argv[2]
html = urllib.request.urlopen(BASE + "/fr/search?q=", timeout=60).read().decode("utf8", "replace")
rows = re.findall(r'<img src="%s/img/([^"]+)"[^>]*>\s*</td>\s*<td>([^<]+)</td>' % re.escape(BASE), html)
mapping = {art.strip(): img for img, art in rows}
raw = open(cat, encoding="utf8").read()
data = json.loads(raw)
done, n = {}, 0
for p in data:
    if p["catalog"] != "Canplast" or p.get("image") or p["article"] not in mapping:
        continue
    img = mapping[p["article"]]
    local = "canplast-" + img.lower()
    if img not in done:
        path = os.path.join(dest, local)
        if not os.path.exists(path):
            open(path, "wb").write(urllib.request.urlopen(BASE + "/img/" + img, timeout=30).read())
        done[img] = local
    p["image"] = "/images/products/" + done[img]
    n += 1
open(cat, "w", encoding="utf8").write(json.dumps(data, ensure_ascii=False))
print(n, "articles,", len(done), "photos")
