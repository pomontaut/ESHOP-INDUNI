#!/usr/bin/env python3
"""Télécharge la photo de chaque article HGC depuis l'API publique de recherche de www.hgc.ch
(une requête par article, 0.3 s entre chaque requête) et écrit le résultat dans un fichier JSON
{article: {"media": id, "file": chemin|None, "status": ...}}. N'écrit RIEN dans le dépôt."""
import json, os, re, sys, time, hashlib, urllib.request, urllib.parse
CAT = sys.argv[1]; OUT = sys.argv[2]; DEST = sys.argv[3]; LIMIT = int(sys.argv[4]) if len(sys.argv) > 4 else 0
UA = {"User-Agent": "Mozilla/5.0 (Induni catalogue sync)", "Accept": "application/json"}
os.makedirs(DEST, exist_ok=True)
items = [i for i in json.load(open(CAT, encoding="utf-8")) if i["catalog"] == "HG COMMERCIALE" and not i.get("image")]
if LIMIT: items = items[:LIMIT]
try: res = json.load(open(OUT))
except Exception: res = {}
def get(url, binary=False):
    req = urllib.request.Request(url, headers=UA)
    with urllib.request.urlopen(req, timeout=30) as r: return r.read()
for n, it in enumerate(items, 1):
    code = it["article"]
    if code in res and res[code].get("status") in ("ok", "no-image", "not-found"): continue
    try:
        data = json.loads(get("https://www.hgc.ch/api/search/autocomplete?term=" + urllib.parse.quote(code)))["data"]["products"]
        prod = next((p for p in data if p["code"] == code), None)
        if not prod: res[code] = {"status": "not-found"}
        else:
            medias = (prod.get("image") or {}).get("medias") or []
            m = next((x for x in medias if x["width"] == 479), None) or (medias[1] if len(medias) > 1 else (medias[0] if medias else None))
            if not m: res[code] = {"status": "no-image"}
            else:
                mid = re.search(r"product[A-Z]+-(\d+)\.", m["url"]).group(1)
                path = os.path.join(DEST, f"hgc-{mid}.jpg")
                if not os.path.exists(path):
                    blob = get("https://www.hgc.ch" + m["url"])
                    open(path, "wb").write(blob)
                    time.sleep(0.15)
                res[code] = {"status": "ok", "media": mid, "file": f"hgc-{mid}.jpg", "sha": hashlib.md5(open(path, "rb").read()).hexdigest()}
    except Exception as e:
        res[code] = {"status": "error", "msg": str(e)[:100]}
    if n % 25 == 0: json.dump(res, open(OUT, "w")); print(n, "/", len(items), flush=True)
    time.sleep(0.3)
json.dump(res, open(OUT, "w"))
from collections import Counter
print("RÉSUMÉ", Counter(v["status"] for v in res.values()))
