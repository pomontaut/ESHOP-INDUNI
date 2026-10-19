#!/usr/bin/env python3
"""Associe chaque article Sika à sa page produit et à sa photo sur che.sika.com/fr.
Les pages sont trouvées par le nom (slug du plan du site products.sitemap.xml : « SikaGrout-214 R »
-> sika-grout... en alphanumérique seulement), la photo est l'image « dynamicmedia » de la page
dont le nom de fichier contient le nom du produit. Aucun prix n'est lu ni écrit (prix confidentiels).
Usage : fetch_sika_media.py <catalog_products.json> <resultat.json> <dossier_images>"""
import json, os, re, sys, time, hashlib, urllib.request, html as H
CAT, OUT, DEST = sys.argv[1:4]
UA = {"User-Agent": "Mozilla/5.0 (Induni catalogue sync)"}
os.makedirs(DEST, exist_ok=True)
def get(url, accept="text/html"):
    with urllib.request.urlopen(urllib.request.Request(url, headers={**UA, "Accept": accept}), timeout=40) as r: return r.read()
def key(s): return re.sub(r"[^a-z0-9]", "", s.lower())
pages = re.findall(r"<loc>([^<]+\.html)</loc>", get("https://che.sika.com/fr/products.sitemap.xml").decode())
by_key = {key(u.rsplit("/", 1)[1][:-5]): u for u in pages}
res, saved = {}, {}
for it in [i for i in json.load(open(CAT, encoding="utf-8")) if i["catalog"] == "Sika"]:
    k = key(it["designation"]); url = by_key.get(k)
    if not url:
        k = key(re.sub(r"^sika\s*", "", it["designation"], flags=re.I)); url = by_key.get("sika" + k) or by_key.get(k)
    if not url: res[it["article"]] = {"match": False}; continue
    if url not in saved:
        try: page = H.unescape(get(url).decode("utf-8", "replace")); time.sleep(0.4)
        except Exception as e: print("page illisible (lien gardé, sans photo)", url, e); saved[url] = None; res[it["article"]] = {"match": True, "fiche": url, "image": None}; continue
        imgs = re.findall(r"https://dynamicmedia\.sika\.com/adobe/assets/[^\"' ]+?\.png", page)
        # strict : une photo d'un autre produit (ex. fût générique « ViscoCrete-2037 ») serait trompeuse
        pick = next((u for u in imgs if re.sub(r"^sika", "", k) in key(u.rsplit("/", 1)[1])), None)
        fn = None
        if pick:
            fn = "sika-" + hashlib.md5(pick.encode()).hexdigest()[:10] + ".png"
            data = get(pick + "?smartcrop=1-1&width=480&height=480&format=png", "image/png")
            open(os.path.join(DEST, fn), "wb").write(data)
        saved[url] = fn
    res[it["article"]] = {"match": True, "fiche": url, "image": saved[url]}
json.dump(res, open(OUT, "w"), ensure_ascii=False, indent=1)
print({a: (bool(e.get("fiche")), bool(e.get("image"))) for a, e in res.items()})
