#!/usr/bin/env python3
"""Associe chaque article EFCO à sa page produit et à sa photo sur efco.swiss/fr (boutique Magento :
recherche par n° d'article, une requête par article, 0.4 s entre requêtes). Le résultat n'est retenu
que si le n° d'article figure dans le bloc du produit trouvé (URL de photo « a30225_1.jpg »).
Usage : fetch_efco_media.py <catalog_products.json> <resultat.json> <dossier_images>
N'écrit RIEN dans le dépôt hors du dossier d'images donné."""
import json, os, re, sys, time, urllib.request, urllib.parse, html as H
CAT, OUT, DEST = sys.argv[1:4]
UA = {"User-Agent": "Mozilla/5.0 (Induni catalogue sync)"}
os.makedirs(DEST, exist_ok=True)
def get(url):
    with urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=40) as r: return r.read()
items = [i for i in json.load(open(CAT, encoding="utf-8")) if i["catalog"] == "EFCO"]
try: res = json.load(open(OUT))
except Exception: res = {}
for n, it in enumerate(items, 1):
    a = it["article"]
    if a in res: continue
    entry = {"match": False}
    try:
        page = get("https://efco.swiss/fr/catalogsearch/result/?q=" + urllib.parse.quote(a)).decode("utf-8", "replace")
        for blk in page.split('<li class="item product product-item">')[1:]:
            if a.lower() not in blk.lower(): continue
            link = re.search(r'class="product-item-link"[^>]*href="([^"]+)"', blk) or re.search(r'href="([^"]+)"[^>]*class="product-item-link"', blk)
            im = re.search(r'data-src="(https://efco\.swiss/media/catalog/product/[^"]+\.(?:jpg|png))"', blk)
            if not link: continue
            entry = {"match": True, "fiche": H.unescape(link.group(1)), "image": None}
            if im:
                fn = "efco-" + a.lower() + ".jpg"; path = os.path.join(DEST, fn)
                if not os.path.exists(path): open(path, "wb").write(get(im.group(1)))
                entry["image"] = fn
            break
    except Exception as e:
        entry["error"] = str(e)
    res[a] = entry
    if n % 25 == 0: json.dump(res, open(OUT, "w"), ensure_ascii=False); print(n, len(items), flush=True)
    time.sleep(0.4)
json.dump(res, open(OUT, "w"), ensure_ascii=False, indent=1)
print("done", len(res), "match:", sum(e["match"] for e in res.values()), "image:", sum(1 for e in res.values() if e.get("image")))
