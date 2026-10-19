#!/usr/bin/env python3
"""Associe chaque article Swisspor à sa page produit et à sa photo sur www.swisspor.com/ch-fr
(recherche du site par nom de produit, une requête par produit distinct, 0.4 s entre requêtes).
Usage : fetch_swisspor_media.py <catalog_products.json> <resultat.json> <dossier_images>
N'écrit RIEN dans le dépôt hors du dossier d'images donné. Le site n'indexe pas les n° d'article :
le rapprochement se fait sur le nom : recherche par les 2 premiers mots, puis la page dont tous les
mots du titre figurent dans le nom de l'article (la plus précise) ; sinon repli sur le lien de
recherche du site, sans photo."""
import json, os, re, sys, time, unicodedata, hashlib, urllib.request, urllib.parse, html as H
CAT, OUT, DEST = sys.argv[1:4]
BASE = "https://www.swisspor.com"
UA = {"User-Agent": "Mozilla/5.0 (Induni catalogue sync)"}
os.makedirs(DEST, exist_ok=True)

def get(url):
    with urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=30) as r: return r.read()
def norm(s):
    s = unicodedata.normalize("NFKD", s).encode("ascii", "ignore").decode().lower()
    return re.findall(r"[a-z0-9]+(?:[.,][0-9]+)?", s)
def words(designation): return re.sub(r"^swisspor\s+", "", designation, flags=re.I).split()

items = [i for i in json.load(open(CAT, encoding="utf-8")) if i["catalog"] == "Swisspor"]
queries = sorted({" ".join(words(i["designation"])[:2]) for i in items})
try: hits_by_q = json.load(open(OUT + ".hits"))
except Exception: hits_by_q = {}
for n, q in enumerate(queries, 1):
    if q in hits_by_q: continue
    try:
        page = get(f"{BASE}/ch-fr/search?q={urllib.parse.quote(q)}").decode("utf-8", "replace")
        hits = []
        for blk in page.split('class="search-result__hit"')[1:]:
            m = re.search(r'href="(/ch-fr/[^"]+)"[^>]*title="([^"]*)"', blk)
            im = re.search(r'<img alt="[^"]*" title="[^"]*" src="(/uploads/media/[^"]+)"', blk)
            if m: hits.append({"href": m.group(1), "title": H.unescape(m.group(2)), "img": im.group(1) if im else None})
        hits_by_q[q] = hits
    except Exception as e:
        print("erreur", q, e, flush=True)
    if n % 25 == 0: json.dump(hits_by_q, open(OUT + ".hits", "w"), ensure_ascii=False); print(n, len(queries), flush=True)
    time.sleep(0.4)
json.dump(hits_by_q, open(OUT + ".hits", "w"), ensure_ascii=False)

res, saved = {}, {}
for it in items:
    w = words(it["designation"]); q = " ".join(w[:2]); dt = set(norm(it["designation"]))
    best = None
    for h in hits_by_q.get(q, []):
        tt = set(norm(h["title"]))
        if tt and tt <= dt and (best is None or len(tt) > best[0]): best = (len(tt), h)
    if not best:
        res[it["article"]] = {"match": False, "fiche": f"{BASE}/ch-fr/search?q={urllib.parse.quote(q)}", "image": None}
        continue
    h = best[1]; img = None
    if h["img"]:
        src = BASE + h["img"].split("?")[0]
        if src not in saved:
            path = os.path.join(DEST, "swisspor-" + hashlib.md5(src.encode()).hexdigest()[:10] + ".jpg")
            if not os.path.exists(path): open(path, "wb").write(get(src))
            saved[src] = os.path.basename(path)
        img = saved[src]
    res[it["article"]] = {"match": True, "fiche": BASE + h["href"], "image": img, "title": h["title"]}
json.dump(res, open(OUT, "w"), ensure_ascii=False, indent=1)
print("done", len(res), "match:", sum(e["match"] for e in res.values()), "image:", sum(1 for e in res.values() if e["image"]))
