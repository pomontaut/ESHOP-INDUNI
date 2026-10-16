# Agents achats INDUNI

Ces documents décrivent la méthode que le module « Sélection multi-fournisseurs »
(`public/catalogue.html`, préfixe `smart*`, environnement test) applique de façon
déterministe, sans appel à un modèle.

- **Acheteur senior** (rigueur de comparaison) : TCO HT, périmètre homogène,
  équivalence stricte, aucune invention, données marquées [F]/[C]/[H],
  « Non précisé » n'est jamais assimilé à « inclus ».
- **Expert Achats, Supply Chain & Optimisation logistique** : coût complet rendu
  chantier, flux physiques, consolidation des commandes, franco, robustesse,
  risques, plan d'action, KPI. Brief complet : `expert_achats_supply_chain.md`.

Ce que l'e-shop applique réellement aujourd'hui (`smartSupplyChainHtml`) :
scénarios comparés (recommandé, article par article, tout chez un fournisseur),
transport via `transportLineItemsInduni`, franco manquant (Canplast, MBT,
Swisspor), taux de remplissage camion (poids connu uniquement), dépendance
mono-source, articles « sur demande », solution la plus robuste (tolérance 3 %
[H]), plan d'action et KPI. Non disponible dans l'e-shop, donc jamais inventé :
distances, OTIF/fiabilité fournisseur, historiques ABACUS, capacités, plannings
travaux, coûts d'attente/déchargement/manutention.
