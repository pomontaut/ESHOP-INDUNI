#!/usr/bin/env python3
"""Photos / schémas CreaBeton depuis creabeton.ch (fabricant ; usage interne d'un client).
Plan du site autorisé par robots.txt (CatItem_1.xml), 5 s entre requêtes (Crawl-delay), UNE page par famille
de pages (slug sans n° d'article : les images sont identiques dans une famille, vérifié).
Photo (« -h- ») prioritaire, sinon 1re image (schéma « -zr- »...). Image réduite à 600 px, WebP.
Usage : fetch_creabeton_media.py <catalog_products.json> <resultat.json> <dossier_images>
Résultat : {article: {"fiche": url, "image": fichier|null}}. N'écrit RIEN dans le dépôt hors du dossier donné."""
import json, os, re, sys, time, io, collections, urllib.request
from PIL import Image
CAT, OUT, DEST = sys.argv[1:4]
UA = {"User-Agent": "Mozilla/5.0 (Induni catalogue sync)"}
os.makedirs(DEST, exist_ok=True)
def get(url):
    with urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=60) as r: return r.read()
arts = {i["article"] for i in json.load(open(CAT, encoding="utf-8")) if i["catalog"] == "CreaBeton"}
sm = get("https://creabeton.ch/CatItem_1.xml").decode()
groups = collections.defaultdict(list)
for loc in re.findall(r"<loc>([^<]*)", sm):
    m = re.search(r"/fr/(.*?)-(\d+)\.html$", loc)
    if m and m.group(2) in arts: groups[m.group(1).split("/")[-1]].append((m.group(2), loc))
try: res = json.load(open(OUT))
except Exception: res = {}
for n, (slug, lst) in enumerate(sorted(groups.items()), 1):
    if all(a in res for a, _ in lst): continue
    img = None
    try:
        html = get(lst[0][1]).decode("utf-8", "replace")
        names = list(dict.fromkeys(re.findall(r'assets/large/([^"]+\.webp)', html)))
        pick = next((x for x in names if "-h-" in x), names[0] if names else None)
        if pick:
            fn = "creabeton-" + pick.replace(".webp", "") + ".webp"; path = os.path.join(DEST, fn)
            if not os.path.exists(path):
                time.sleep(5)
                im = Image.open(io.BytesIO(get("https://creabeton.ch/CatCache/catcache.1/others/assets/large/" + pick)))
                if im.mode not in ("RGBA", "RGB"): im = im.convert("RGBA")
                im.thumbnail((600, 600)); im.save(path, "WEBP", quality=82)
            img = fn
    except Exception as e:
        print("ERR", slug, e, flush=True); continue
    for a, loc in lst: res[a] = {"fiche": loc, "image": img}
    json.dump(res, open(OUT, "w"), ensure_ascii=False)
    print(n, len(groups), slug, img, flush=True)
    time.sleep(5)
print("done", len(res), "image:", sum(1 for e in res.values() if e["image"]))
