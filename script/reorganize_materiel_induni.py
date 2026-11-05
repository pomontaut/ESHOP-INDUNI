#!/usr/bin/env python3
"""Réorganise le catalogue « Matériel Induni » en Famille › Sous-famille › Détail.
Ancienne famille -> sousFamille ; ancienne sousFamille -> sousSousFamille (détail).
Usage : python3 script/reorganize_materiel_induni.py db/seed_data/catalog_products.json"""
import json, sys
TREE = {
 "Lubrifiants et contenants": ["Lubrifiant et carburant Entretiens","Bac rétention / citerne / bidon"],
 "MATERIEL DU COMMERCE": ["Chauffage et ventilation","Mobilier / électroménager"],
 "Coffrage / accessoires": ["Coffrage / accessoires"],
 "MATERIEL DE CHANTIER": ["Echelle","Chevalet","Coffre et rangement","Gardes corps","Pompe à béton","Pompes à eau"],
 "MATERIEL/ACCESSOIRES GAZ": ["Equipement gaz"],
 "MATERIEL / ACCESSOIRES ELECTRICITE": ["Equipement Électrique"],
 "OUTILLAGE": ["Matériaux de construction","Autre électroportatif","Appareil scellement","Outillage électroportatif","Outillage manuel","Forage / démolition","Menuiserie","Rabotage talochage et traitement de sol et mur","Sciage / coupe","Serrurerie","Tuyau alimentation eau / air"],
 "MANUTENTION/LEVAGE": ["Manutention","Matériel de levage","Levage spécifique","Colisage","Mesure / Peson","Implantation mesure / traçage"],
 "CONSOMMABLES": ["Fixation","Consommable","Container outillage","Nettoyage entretiens","Soudure","Traitement eau","Peinture et application"],
 "SECURITE/PROTECTION": ["Autre sécurité EPI","Protection auditive","Protection de la tête","Protection des mains","Protection des pieds","Protection des yeux","Protection incendie","Protection respiratoire","Protection sur chantier","Protection travail en hauteur","Pharmacie / hygiène"],
 "SIGNALISATION/CLOTURE DE CHANTIER/GESTION TRAFIC": ["Fermeture de chantier","Signalisation routière et panneaux","Télécommunication - radio"],
 "Publicité / objet de communication": ["Publicité / objet de communication"],
}
RENAME = {"Electricité": "Equipement Électrique"}  # ancien libellé -> sous-famille de la liste
PARENT = {s: f for f, subs in TREE.items() for s in subs}
path = sys.argv[1]
d = json.load(open(path))
n = 0
for p in d:
    if p.get("catalog") != "Matériel Induni": continue
    old_f = p["famille"]
    if p.get("sousSousFamille") not in (None, "__DIRECT__") and old_f in PARENT:
        continue  # déjà réorganisé
    sub = RENAME.get(old_f, old_f)
    if sub not in PARENT: sys.exit(f"Sous-famille inconnue : {old_f}")
    p["sousSousFamille"] = p["sousFamille"] or "__DIRECT__"
    p["sousFamille"] = sub
    p["famille"] = PARENT[sub]
    n += 1
json.dump(d, open(path, "w"), ensure_ascii=False)
print(n, "articles réorganisés")
