# ESHOP-INDUNI

Rails procurement app for Induni & Cie SA (Swiss construction company).
Employees order construction materials from a set of supplier catalogs
through a single-page app; buyers/admins manage suppliers, chantiers
(worksites), users and pricing.

Primary contact / owner: pomontaut@induni.ch (Pierre-Olivier Montaut),
communicates in French, terse and direct, reports real production bugs from
screenshots of actual sent orders.

## Architecture

- **Rails 8** backend (`app/controllers/api/*` for the SPA's JSON API,
  `app/controllers/admin/*` for server-rendered admin CRUD screens).
- **`public/catalogue.html`** is the entire customer-facing SPA: one huge
  HTML file with inline `<style>` and multiple inline `<script>` blocks, no
  build step, no framework. It is served as a static file and talks to the
  Rails JSON API. When editing it, always JS-syntax-check before committing:
  ```
  node -e "const fs=require('fs');const html=fs.readFileSync('public/catalogue.html','utf8');[...html.matchAll(/<script>([\s\S]*?)<\/script>/g)].forEach((m,i)=>{try{new Function(m[1])}catch(e){console.log(i,e.message)}})"
  ```
- Key models: `Supplier`, `Product`, `Order`/`OrderLine`, `User`, `Chantier`,
  `DieselPrice`, `CanplastSurcharge`.
- Order PDF is rendered **server-side** from `app/views/orders/bon_de_commande.html.erb`
  via `ApplicationController#render_order_pdf` (WickedPdf) — this is what's
  actually emailed to suppliers. `public/catalogue.html`'s client-side
  `buildOrderHtml()` is a *separate* implementation used only for the
  "Prévisualisation"/download-PDF fallback; keep both in sync when either
  changes, since the emailed PDF does NOT reuse the client HTML.

## Suppliers (13 as of this writing)

HGC, Canplast, Leuba HIAG, CreaBeton, MBT, ALZO AG, Soreval, BTest, LCBE,
Sika (confidential pricing), GANAMAT SA. Seeded from
`db/seed_data/catalog_products.json` + `lib/tasks/catalog_seed.rake`'s
`required_suppliers` hash.

**When adding a new supplier/catalog, always add it to `User::SUPPLIERS`**
(`app/models/user.rb`) — this list drives the admin "catalogues fournisseurs"
checkboxes. Forgetting it means admins can never explicitly grant/restrict
that catalog, and — combined with the blank-array bug below — can make the
catalog silently invisible to users with any manual restriction.

## Critical rules learned the hard way

- **Confidential pricing (`Supplier#confidential_pricing`, e.g. Sika)**: the
  real net price must NEVER reach the browser or a supplier PDF outside the
  Analyse achat module. This has leaked multiple times through different
  paths — check all of these whenever confidential pricing changes:
  `Api::ProductsController#index` (masks to 0), stale in-browser cart state
  (`refreshCartFromCatalog()` in catalogue.html re-fetches before generating
  any order), `catalog_seed.rake`'s idempotent seed (a Sika supplier
  auto-created via `find_or_create_by!` elsewhere could get
  `confidential_pricing: false` and never get corrected — see the explicit
  `Supplier.where(name: "Sika", confidential_pricing: false).update_all(...)`
  correction), and the order PDF template itself
  (`orders/bon_de_commande.html.erb` — must show "Conformément à nos accords
  cadre" instead of any price/montant for confidential suppliers).
- **`catalog_seed.rake`'s `required_suppliers.each { |name,attrs| ...
  update!(attrs) if supplier.new_record? }`** only applies attrs to brand-new
  rows — it will NEVER retroactively fix an existing supplier. Any
  correction to already-seeded data needs an explicit one-time
  `Supplier.where(...).update_all(...)` line after the loop (see the Sika
  and CreaBeton/Soreval examples in that file).
- **`allowed_suppliers` hidden-blank-fallback**: the admin user form submits
  a trailing empty `allowed_suppliers[]` even when every checkbox is
  unchecked. Always `.reject(&:blank?)` this param server-side
  (`Admin::UsersController#user_params`) — otherwise `["", ...]` is treated
  as an explicit (and empty-intersecting) restriction, hiding every catalog
  from that user. `User#effective_visible_suppliers` also treats a
  blank-only array as "no restriction" defensively.
- **Order contact data**: `Order` has `contact`, `phone`,
  `delivery_address`, `conducteur_travaux` columns, persisted by
  `Api::OrdersController#create` from the order form. Never hardcode a
  name/address in the PDF template again — it happened once already
  (`bon_de_commande.html.erb` used to show "Pierre-Olivier MONTAUT" and the
  Induni depot address unconditionally).
- **Chantier visibility** (`Chantier.visible_to`) has 3 tiers: admin → all;
  `User#chantier_access_scope == "secteur"` → all chantiers sharing
  `Chantier#secteur` with the user's `User#sector`; default → only
  chantiers where the user's email matches `email_technicien` /
  `email_contremaitre` / `email_chef_equipe`.
- **HTTP caching**: `/api/*` responses always set `Cache-Control: no-store`
  (`ApplicationController#prevent_api_caching`) — some browsers (observed:
  Edge, not Firefox) heuristically cache JSON GETs with no explicit header,
  serving stale/empty catalogs indefinitely.
- **`equivalence_key` (HGC ↔ Canplast, etc.)**: every time new HGC reference
  data is added or updated (new tariff, new products), re-check whether it
  should be linked to/unlinked from its Canplast (or other supplier)
  equivalent. Only an EXACT diameter match is a valid equivalence — never a
  nominal/rounded DN-to-OD approximation (e.g. DN100 ≠ Ø110mm). This was
  explicitly corrected once already after 16 mismatched links were seeded by
  mistake (see the `unlink_coude_equivalences_with_mismatched_diameter`
  migration) — always verify the real diameter on both sides before setting a
  shared `equivalence_key`, not just the product family/designation.
- **Delivery/transport fees (RPLP, zones, forfaits, HILTI, Matériel Induni...)
  are computed ONLY client-side, in `catalogue.html`** — there is no
  server-side re-derivation of this pricing logic, by design (one source of
  truth instead of duplicating per-supplier tariffs in Ruby). The pipeline is:
  `transportDetailsInduni(sub,supplier,weightOverride,chantierNom)` (raw
  numbers) → `transportHtmlInduni(...)` (cart/preview display) and
  `transportLineItemsInduni(...)` (the same fees as a plain `[{label,
  amount}]` array) → `sendOrderByEmail` sends that array as `extra_charges` in
  the `/api/orders` POST body → `Api::OrdersController#create` persists it
  verbatim to `Order#extra_charges` (JSON column, no recomputation) →
  `Order#grand_total` and the "totals" box in `orders/bon_de_commande.html.erb`
  (the real emailed PDF) render it. **Adding a new supplier fee (or changing
  an existing one) means updating all three of `transportDetailsInduni`,
  `transportHtmlInduni` AND `transportLineItemsInduni`** — the ERB template
  and `Order` model never need touching since they're generic over
  `extra_charges`, but forgetting `transportLineItemsInduni` specifically
  (easy to do, since the cart/preview UI already looks correct via
  `transportHtmlInduni` and nothing locally signals the gap) silently drops
  the fee from the real PDF sent to the supplier — exactly how the Canplast
  delivery-fee bug happened (fee computed and shown everywhere in the
  browser, but never sent to the backend at all, for every supplier with
  transport logic, not just Canplast). Confidential-pricing suppliers must
  keep masking `extra_charges` the same way as the merchandise total.

## Fournisseur : plusieurs adresses e-mail de commande

**Tous** les champs e-mail d'un fournisseur (`Supplier::EMAIL_COLUMNS` : défaut, 2e adresse, canton)
accettent une ou plusieurs adresses séparées par `,` `;` ou espace, normalisées en
« a@x.ch, b@x.ch » (`before_validation`, champs `text_field` — pas `email_field`, le
navigateur refuse `;`). Les adresses invalides sont nommées dans l'erreur.

`Supplier#email_secondaire` (Admin > Fournisseurs, optionnelle) s'ajoute à l'adresse
principale **ou** à celle du canton du chantier : `Supplier#order_emails(canton)`
= destinataires séparés par une virgule, utilisé par `OrderMailer` (envoi,
relance), `Api::OrdersController` et — côté SPA — `supplierOrderEmailInduni()`
(`supplierDefaultEmails` + `supplierExtraEmails` de `/api/me`) pour pré-remplir le
champ « À » (modifiable) et pour la sélection multi-fournisseurs. Le bon de
commande PDF affiche les deux adresses.

## Plusieurs personnes par rôle sur un chantier (gros chantiers)

La personne « principale » (technicien, contremaître, chef d'équipe, contact
réception livraison) reste dans les colonnes de `chantiers` ; les autres sont des
`ChantierContact` (role/nom/natel/email), saisies par « ＋ Ajouter … » dans Admin >
Chantiers (`accepts_nested_attributes_for :contacts`, ✕ ou champs vidés =
suppression). Effets : l'e-mail d'un technicien/contremaître/chef d'équipe
supplémentaire donne accès au chantier (`Chantier.visible_to`) et est repris par
`Chantier.matching_person` (affectations) ; `/api/me` expose `techniciens`,
`emailsTechnicien` (tous en copie de commande) et `contactsLivraison` (liste
proposée dans le champ « contact » du bon de commande, téléphone auto) via
`Chantier#team_json`. Le contact de réception supplémentaire ne donne PAS accès au
chantier. Le conducteur de travaux reste unique (approbateur N+1).

## Visibilité des commandes par chantier / remise à zéro

**Un utilisateur non-admin ne voit que les commandes des chantiers qui lui sont
visibles** (`Order.visible_to(user)` = `Chantier.visible_to` : e-mail sur la fiche
chantier, secteur, ou affectation explicite Admin > Utilisateurs > « Chantiers »),
quel que soit l'auteur de la commande — et plus ses propres commandes sur d'autres
chantiers. Appliqué partout : Dashboard (`Api::OrdersController#index`) ET pages
serveur `/orders` + `/orders/:id/order_lines` (qui étaient ouvertes à tout
utilisateur connecté). Le chantier d'une commande n'a pas de clé étrangère : il est
lu dans `notes` (« Chantier: <nom> | … »), voir `Order.chantier_name_of`.
`Api::OrdersController#create` n'impose pas (encore) que le chantier saisi soit
l'un des siens. Reste ouvert à tout utilisateur connecté : `/products`, `/suppliers`
(CRUD historique, prix y compris confidentiels) — à restreindre.
Admin > Commandes (`Admin::OrdersController`, propriétaire seulement =
`User::PERMANENT_ADMIN_EMAILS`) : export CSV puis « VIDER LES COMMANDES » (phrase à
taper). `OrderNumberFloor` garde la numérotation ESHOP_INDUNI_nn après purge (case
« repartir à 01 » en option).
Champ « Conserver ces commandes » (numéros exacts, ex. une vraie commande) : tout est
supprimé SAUF ceux-là ; un numéro inconnu annule l'opération ; la numérotation continue
alors toujours. Barre de recherche du Dashboard (`GET /api/orders?q=`, `Order.matching_query`) : tous les mots
saisis (sans accents/casse, début ou milieu de mot) parmi n° de commande, fournisseur,
chantier, auteur et référence + nom de chaque article ; porte sur les 3'000 commandes
visibles les plus récentes (résultat ≤ 500), toujours limitée à `Order.visible_to` ; les
articles trouvés s'affichent sous le n° (`dashMatchedItemsHtml`).
Bouton « 🗑 Supprimer » par ligne du Dashboard (`DELETE /api/orders/:id`) :
admin uniquement (bouton masqué ET 403 côté serveur), supprime commande + lignes sans
envoyer d'e-mail (le fournisseur n'est pas prévenu — « Annuler » sert à ça), le numéro
n'est jamais réattribué. « Envoyer à… » (Dashboard, `POST /api/orders/:id/forward`) : copie d'une
commande déjà envoyée à une autre adresse + Cci optionnel à l'utilisateur, sans toucher
à l'historique d'envoi ; redirigé vers l'adresse de test en environnement test.

## Photos des articles HGC (récupérées sur www.hgc.ch)

460 des 614 articles HGC ont une photo (`image` = `/images/products/hgc-<id média>.jpg`, 479 px,
213 fichiers : les variantes d'un même produit partagent la photo). Source : l'API
publique de recherche de HGC, `GET https://www.hgc.ch/api/search/autocomplete?term=<n° article>`
(renvoie `image.medias` en 240/479/958 px) ; script réutilisable `script/fetch_hgc_images.py`
(args : catalogue JSON, fichier de résultats, dossier de destination, limite) qui n'écrit
que les articles SANS image, 0,3 s entre requêtes. 114 articles absents du site public
HGC restent sans photo (icône grue). Un nouvel article HGC : relancer le script puis
renseigner `image` dans `catalog_products.json`. Les photos appartiennent à HGC (usage
interne d'un client).

## Fiche article + photos : Swisspor, Sika, ALZO

`Product#fiche_url` (colonne, seed `ficheUrl` de `catalog_products.json`, exposée par `/api/products`
en `ficheUrl`) → lien « 🔗 Fiche article » (`supplierSheetLinkHtml`, même emplacement que le lien HGC).
Aucun stock pour ces fournisseurs. Récupération sur les sites fournisseurs (usage interne, photos
copiées dans `public/images/products/`) : **Swisspor** `script/fetch_swisspor_media.py` (recherche du site par
2 premiers mots du nom, page = titre dont tous les mots figurent dans l'article ; 836/1248 pages exactes
+ 820 photos 300x200, le reste = lien de recherche swisspor.com sans photo) ; **Sika**
`script/fetch_sika_media.py` (plan du site `products.sitemap.xml`, photo seulement si le nom de fichier
contient le produit : 19/20 liens, 13/20 photos ; Sikament MFD-1 A introuvable ; aucun prix lu —
prix confidentiels) ; **ALZO** une seule fiche (`/francais/gamme-d-articles/saturn-s-simple/`) et sa
photo pour les 168 articles Saturn S ; **EFCO** `script/fetch_efco_media.py` (boutique efco.swiss, recherche
par n° d'article, retenu seulement si le n° figure dans le bloc produit : 345/347 pages + photos 300x300, les
51 photos déjà présentes sont conservées ; les liens de variantes portent leurs paramètres `?…=`) ;
**HILTI** simple lien de recherche `hilti.ch/fr/search?text=<n° article>` (site protégé par un script anti-robot,
API interne inaccessible : ni page exacte ni photo ; recherche non vérifiée côté navigateur). Nouveaux articles : relancer le script puis fusionner
`ficheUrl`/`image` dans le JSON.

## Photos « Matériel Induni » (catalogue dépôt logistique, PDF 25.02)

195 des 997 articles Matériel Induni ont une photo extraite du PDF « Catalogue Dépôt 25.02 »
(`public/images/products/induni-<page>-<n>.jpg`, 57 fichiers, ≤ 480 px). Aucun article ajouté : seules
les lignes du PDF retrouvées dans notre catalogue (nom exact ou proche ≥ 0.85, 626/997) reçoivent une photo.
Le PDF ne place qu'une photo par bloc de lignes (souvent hétérogène : la fontaine à eau en face des
chauffe-gamelles) : chaque photo a été contrôlée à l'œil et limitée aux libellés qu'elle montre vraiment
(règles par photo, ex. « Cône de signalisation », « Mèche SDS-plus »). Les conteneurs, machines et
locations du PDF ne sont pas dans notre catalogue. Nouveau PDF : refaire l'extraction (`pdfimages`,
`pdftohtml -xml` pour les positions) et le contrôle visuel — ne jamais attribuer une photo de bloc à tout le bloc.

## Leuba HIAG : bois au PAQUET (pas au m³)

Les 8 articles Leuba tarifés au m³ (carrelets/planches de coffrage, plateau bois C24)
sont au paquet : prix paquet = prix m³ × (ép × larg × long × « Pcs/pqt N »), unité
`paquet`, descriptif « Prix au paquet (N pcs = x m³, soit CHF y/m³) » (migration
`LeubaHiagPricesPerPaquet` + `catalog_products.json`). Les équivalences HGC (m³) sont
conservées : `comparablePrice()` reconvertit le paquet en m³ (`paquetVolumeM3`) pour
l'affichage du comparatif, et `cartEquivalenceGroups` n'accepte que des équivalents de
MÊME unité (jamais comparer 1 m³ à 1 paquet). Anciennes commandes Leuba : quantité en
m³ au prix m³ (lignes inchangées), mais le produit porte maintenant l'unité « paquet ».

## Navigation : flèche « retour » du navigateur

Dernier `<script>` de `catalogue.html` : `render()` est enveloppée — chaque changement
d'écran (`state` + contenu de `#searchBox`) fait un `history.pushState`, un simple
re-rendu n'ajoute rien, la frappe dans la recherche fait un `replaceState` ; `popstate`
restaure `state` et la recherche puis re-rend (sans repousser d'entrée) et ferme
panier/fenêtres. Un nouvel écran qui n'utilise pas `state`/`render()` (ex. écrans
construits directement dans `#app`) n'a pas d'entrée d'historique propre.

## Bois & Coffrage : libellés Planche / Carrelet / Plateau bois C24

Plus de « Carrelets / planches de coffrage » : rubrique « Planches de coffrage »
(27x…, 40x… → désignation « Planche de coffrage … »), rubrique « Carrelets » (80x120,
80x160 → « Carrelet … ») et « Plateau bois C24 » (ex-« Bois C24 »), HGC et Leuba
(migrations `RenameCarreletsPlanchesToPlanche`, `RenameBoisC24ToPlateauBoisC24`, JSON
du catalogue et liste `subs` de « Bois & Coffrage » dans `catalogue.html`). Les
références d'article ne changent jamais.

## HGC : « Enlèvement dépôt » (production)

Case `#hgcPickupToggle` dans le panier (visible seulement pour HG COMMERCIALE,
`hgcPickup()`), décochée à la vidange du panier : `transportDetailsInduni`
renvoie 0 (transport fixe, carburant et grue), `transportHtmlInduni` /
`transportLineItemsInduni` suivent. L'information voyage via `Order#pickup`
(colonne booléenne, posée par `Api::OrdersController#create` uniquement pour
HG COMMERCIALE) : le PDF serveur (`bon_de_commande.html.erb`) et l'aperçu client
(`buildOrderHtml`) affichent « ENLÈVEMENT AU DÉPÔT PAR INDUNI » à la place de
l'adresse de livraison, et l'e-mail par défaut le précise. Adresse du dépôt HGC
volontairement absente (non communiquée).

## Droits d'affichage « Validation de commande » / « Activer les alertes »

`User#can_validate_orders` et `#can_enable_alerts` (défaut vrai : l'interface
existante est conservée), cases dans Admin > Droits (`new`/`edit`), exposées par
`/api/me` (toujours vraies pour un admin) et appliquées dans `catalogue.html`
(`orderApprovalsNavLink`, `pushNotifBtn` via `_hidePushBtn`). Effet purement
d'interface : les liens Approuver/Refuser des e-mails et les abonnements push
déjà créés continuent de fonctionner.

## Profil « Formation : vue Contremaître » (production)

Profil admin (`TestProfilesController::TRAINING_PROFILE`) pour former en production : vue Contremaître, interface de
PRODUCTION (panier unique : ni sélection multi-fournisseurs ni saisie vocale, ni onglet Réceptions), aucun e-mail
fournisseur (mêmes garde-fous que l'environnement test), bandeau « FORMATION ».

## Sélection multi-fournisseurs (environnement test uniquement)

Dernier `<script>` de `public/catalogue.html` (préfixe `smart*`), activé par
`smartBuyInit()` seulement si `perms.test_profile` (menu Admin > « Environnement test : Développement (admin) », qui garde tous les droits admin — `dev_mode` —, ou vues Contremaître/Conducteur
de l'environnement test admin). Cases « Ajouter à la sélection » sur les fiches
(`productCard`/`productCardFast` enveloppées), panier flottant 🧺, optimiseur
client-side : chaque besoin = ses équivalents (`equivalenceKey` + même unité),
coût d'un groupe fournisseur = `transportLineItemsInduni` (donc toute nouvelle
règle de transport y est reprise automatiquement), recherche exhaustive
(≤ 20'000 combinaisons) sinon recherche locale. Envoi = un `POST /api/orders`
par fournisseur (le serveur recalcule seuils d'approbation/numérotation), seule
saisie : date de livraison (+ conducteur si non déductible du chantier).
Règles : catalogue dépôt (EFCO, HILTI, Matériel Induni) exclu ; fournisseurs à
prix confidentiel jamais comparés (fournisseur imposé, prix 🔒) ; prix
re-téléchargés (`/api/products`) avant calcul et avant envoi ; zones Canplast/
Soreval inconnues = hypothèse prudente signalée ET envoi bloqué.

Analyse Supply Chain du module (`smartSupplyChainHtml`, méthode de l'agent
« Expert Achats, Supply Chain & Optimisation logistique », voir `docs/agents/`) :
scénarios + coût complet, flux, franco manquant, risques, robustesse (tolérance
`SMART_ROBUST_TOLERANCE` = 3 % [H]), plan d'action, KPI. Elle n'utilise que des
données existantes ; ne jamais y inventer distance, OTIF ou capacité.

**Environnement test = aucun e-mail au fournisseur.** `Api::OrdersController#create`
force `to` = `Api::TestProfilesController::TEST_RECIPIENT` (pomontaut@induni.ch),
supprime les copies (technicien…), préfixe l'objet « [TEST] » et redirige la
demande d'approbation vers la même adresse, quel que soit le `to`/`cc` envoyé par
le navigateur (profils Contremaître, Conducteur et Développement). Les commandes de
test sont néanmoins enregistrées (Dashboard/Analyse). Dans la sélection
multi-fournisseurs : date de livraison PAR commande (`SMART_DATES`), zone Soreval/
Canplast modifiable, fournisseur imposé par ligne (`SMART_OVERRIDE`), quantités et
retrait de lignes éditables dans la page.

## Réception de commande et appels de livraison (environnement test uniquement)

Bouton « 📦 Réceptions 🧪 » (`recInit()`, dernier `<script>` de `catalogue.html`, préfixe `rec*`, vue
`state.view === 'receptions'` branchée dans `render()`), visible seulement dans « Environnement test : Développement » (`perms.dev_mode`),
pas dans les vues Contremaître / Conducteur ; `Api::ReceptionsController` (`/api/reception/*`) refuse (403) hors dev_mode. La commande d'achat =
la commande de l'e-shop (pas d'ABACUS), périmètre `Order.visible_to`. Types `OrderReceptionTracker::TYPES` :
C1 diffus (< 5'000 CHF), C2 livraison unique, C3 multijours, C4 multirotations (programme journalier =
`DeliveryCall#slots`), C5 prestation/sous-traitance (réception par avancement %, `Reception#progress_percent`) ;
type proposé automatiquement (C2 pour un fournisseur à prix confidentiel, jamais de seuil exposé), modifiable
(`Order#reception_type`). Modèles : `DeliveryCall`(+`Line`) = appel de livraison, `Reception`(+`ReceptionLine` livré/
accepté) = un BL/camion, `ReceptionScan` = scan/photo de BL **stockée en base** (JPEG/PNG/WebP/PDF ≤ 8 Mo, 10
max ; photos réduites à 1800 px côté navigateur), `Order#invoiced_at` = Facturé. Suivi calculé par
`OrderReceptionTracker` (Commandé / Planifié / Livré / Accepté / Restant / Facturé). Aucun prix n'est exposé.
Tables sans clé étrangère SQL : la purge Admin > Commandes les nettoie elle-même. Pour sortir du test :
retirer le garde `require_test_environment` et rendre le bouton visible à tous.

## E-shops Tinguely (VD) et SGTT (GE) — en production

Prestations d'aspiratrice/pompage/transport de déchets (4 articles chacun, dans
`db/seed_data/catalog_products.json`). Mis en production : `Supplier::TEST_ONLY_NAMES`
est vide (le masquage hors mode Développement reste en place pour un futur e-shop en test) et la
couverture d'accueil n'exige plus `perms.dev_mode`. Visibles selon `effective_visible_suppliers`
(cocher le catalogue dans Admin > Utilisateurs en cas de restriction). Réservés à un canton via
`Supplier#visible_cantons` (Tinguely = VAUD, SGTT = GENEVE), contrôlé avant
envoi par `supplierCantonGuardInduni` (bloque si le canton du chantier diffère,
confirmation s'il est inconnu). Tinguely : prix = tarif − rabais 8 % déjà
appliqué (PU catalogue rappelé dans le descriptif) + ASTAG 4.2 % ajouté en frais
annexe (`transportDetailsInduni`/`Html`/`LineItems`, base = montant net : [H]).
SGTT : aucun frais annexe (transport compris dans les forfaits). E-mails de
commande non communiqués : à saisir dans Admin > Fournisseurs avant tout envoi.
Exclus de la sélection multi-fournisseurs (prestations).

## HGC : fiche article et stock (hgc.ch)

Sur chaque fiche HG COMMERCIALE (`stockStatusBadgeHtml` → `hgcSheetLinkHtml`) : lien
« Fiche HGC » (`hgc.ch/fr/search?text=<n° article>` redirige vers la fiche) et bouton
« Stock HGC (NPA 1213) » → `GET /api/hgc_stock/:article[?zip=]` (`HgcStock`, cache 15 min).
Pas d'API HGC : la fiche embarque `stockLevelStatus` calculé pour le NPA du cookie anonyme
`hgc.anonymousZipCode` (défaut `HGC_STOCK_ZIP`=1213), lu par scraping — fragile si HGC change
son site ; en cas d'échec le bouton affiche « indisponible » sans bloquer. Statut
purement informatif, jamais utilisé pour bloquer une commande.

## Nomenclature Induni (bibliothèque d'articles, admin seulement)

Menu Admin > « 📚 Nomenclature Induni » (`showNomenclatureInduni()`, `state.view === 'nomenclatureInduni'`,
dernier bloc avant `confirmNomenclature` dans `catalogue.html`) : une ligne = un article Induni (n° compta,
segmentation 1-3, n° de référence INDUNI + désignation) rattaché à l'article d'UN fournisseur (référence,
désignation, unité de prix) ; plusieurs fournisseurs = plusieurs lignes de même référence INDUNI. Table
`nomenclature_entries` (`NomenclatureEntry`), alimentée par `catalog:seed` depuis
`db/seed_data/nomenclature_induni.json` (clé référence INDUNI + fournisseur + référence fournisseur ; le JSON est la
source de vérité : le seed crée/met à jour ET supprime les lignes absentes, n° renumérotés compris). API
`GET /api/nomenclature_induni` (`Api::NomenclatureInduniController`, 403 hors `admin?`, AUCUN prix) ; colonne ✓/⚠
= la référence fournisseur existe encore au catalogue (`Product`). Filtre multi-mots + export CSV (« ; », UTF-8 BOM).
À ne pas confondre avec « Gestion nouveaux articles » (`/api/nomenclature`, classement des articles issus d'un
import de devis, profils achats). Ajouter des articles = régénérer le JSON depuis le classeur « Nomenclature INDUNI » :
`python3 script/build_nomenclature_json.py <classeur.xlsx>` (feuille « Base article », **toutes les lignes avec un n° INDUNI sont
intégrées** — option `--only-oui` pour ne reprendre que la colonne A = « oui » ; colonnes B n°compta, C-E segmentation 1-3, F n° INDUNI, G désignation INDUNI, H-J fournisseur,
K unité, **L mots clefs de recherche** séparés par « ; ») puis déployer. Numérotation INDUNI : 9 chiffres FF SS NNNNN, séquentielle
dans chaque sous-famille dans l'ordre de la segmentation ABACUS (catégorie → dimension) ; segmentation 1-3 = Famille / Sous-famille /
Catégorie de la base ABACUS ; colonne M « Libellé ABACUS » = famille d'achat + dimension.
**Mots clefs de recherche (colonne L)** : `NomenclatureEntry#search_keywords`, exposés par `/api/products` en `induniKeywords`
(et `searchKeywords` côté admin) et indexés dans la recherche du catalogue (`productTextV49`, `searchHaystackInduni`) avec le n° et
la désignation INDUNI : un utilisateur qui tape un de ces mots (« culotte », « raccord en Y », « clapet anti-retour »…) retrouve l'article.
Sur les fiches : `/api/products` ajoute `induniReference` / `induniDesignation` (jointure fournisseur + référence, sans prix,
pour tous les utilisateurs) ; `induniRefHtml()` les affiche en petit sous le n° d'article (`productCard`, `productCardFast`) et
`productTextV49` / `scoreProductV49` les indexent : le n° INDUNI sert à la recherche.

## Agent d'usage de l'e-shop (administrateur seulement)

Menu Admin > « 🕵️ Agent d'usage » (`showUsageAgent()`, `state.view === 'usageAgent'`, dernier `<script>` de
`catalogue.html`, préfixe `usg*`). Mesure, pour les utilisateurs **hors administrateurs et service achats**
(`User#usage_tracked?`), les ouvertures de l'e-shop, le temps actif, les clics, les mots tapés (premiers mots),
la navigation et les parcours jusqu'au panier (durée, clics, moyen : barre de recherche / liste-entonnoir / images).
Tables `usage_sessions`, `usage_events`, `usage_reports` ; `Api::UsageController` (`POST /api/usage/events` utilisateurs
suivis ; `GET /api/usage/report`, `POST /api/usage/send_report` admin) ; calcul et e-mail du soir dans `UsageReport`
(`run_due!` : thread Puma, 18h30 Zurich, une fois par jour avec activité, `USAGE_REPORT_AUTO=false` pour couper).
Un nouvel écran de l'e-shop doit passer par `state`/`render()` pour apparaître dans le suivi de navigation. Détail :
`docs/agents/agent_usage_eshop.md`.

## Agent « moteur de recherche » (chat administrateur) et mémoire de recherche

Bouton « 🔎 Agent recherche » (administrateurs réels hors profils test, dernier `<script>` de `catalogue.html`, préfixe `srch*`) :
chat (`Api::SearchAgentController`, `SearchAgent`) qui mémorise synonymes et mots clefs supplémentaires par article
(`SearchMemory`, tables `search_memories` / `search_agent_messages`). Appliqué tout de suite à tous : synonymes via
`GET /api/search_memory` (injectés dans `SEARCH_SYNONYM_MAP_V49`), mots clefs fusionnés dans `induniKeywords` de `/api/products`.
Lit les retours de l'agent d'usage (« bilan », « suggestions » = mots clefs d'après les parcours réels). « teste … » lance le
vrai moteur du navigateur. Français libre via l'API Claude (`SearchAgent::Brain`, outils, `ANTHROPIC_API_KEY`) avec repli sur commandes fixes ;
**règles de classement** (`SearchMemory.rules_json`, `srchRuleBonus` enveloppe `scoreProductV49`, règles intégrées drainage/structuré) ; le navigateur envoie à
l'agent le contexte mesuré du moteur (`srchEngineContext`) pour les « pourquoi ». Détail : `docs/agents/agent_moteur_recherche.md`. La « Recherche guidée » (menu déroulant
catalogue › famille › sous-famille, `renderFunnelWidget`) est aussi présente sur la page d'un groupe de familles HGC
(ex. Canalisation).

## Indicateurs (administrateurs seulement) : construction de l'e-shop, commandes, utilisation

Menu Admin > « 📊 Indicateurs » (`showIndicators()`, `state.view === 'indicators'`, dernier `<script>` de `catalogue.html`, préfixe `ind*`,
graphiques SVG) ← `GET /api/indicators?from=` (`Api::IndicatorsController`, admin). **Construction** (table `eshop_metrics`, `EshopMetric`,
un relevé par jour) : références articles (avec une famille), articles en équivalence (clé partagée par ≥ 2 catalogues) et %,
articles avec n° + désignation INDUNI et %, catalogues fournisseurs, photos et %. L'historique depuis le 1er octobre est reconstitué depuis
git (`python3 script/build_eshop_metrics_history.py` → `db/seed_data/eshop_metrics_history.json`, nécessite `git fetch --unshallow`),
semé par la migration ; les jours suivants sont mesurés en direct (thread Puma toutes les 30 min, `EshopMetric.snapshot!`, la dernière valeur
du jour fait foi). **Commandes** : par jour de création (Zurich) hors commandes d'essai `[TEST]`, avec cumul. **Utilisation** : séries
journalières de l'agent d'usage (`UsageReport.build`).

## Note de marché PowerPoint (GC / BAT)

Boutons « 📊 Note de marché PowerPoint » en tête de Analyse achat > Indicateurs de marché
(`downloadNoteMarche('GC'|'BAT')` dans `catalogue.html`). Génération 100 % navigateur, en un clic :
`public/note_marche_pptx.js` (`NoteMarchePptx.generate`) + `public/jszip.min.js` (JSZip 3.10.1, copie locale)
reprennent le modèle `public/templates/modele_induni.pptx` (diapos d'origine supprimées, couverture / chapitres / pages
« Vierge Light » du modèle) et les données déjà exposées à l'écran (KBOB, Brent, EUR/CHF, ASTAG, Canplast,
`acier_armature_prices.json`, captures `market_charts/ferraille_turquie.png` et `zinc.png`). Sections : 1 énergie – matières
premières (identique GC/BAT), 2 taux de change + ASTAG + acier d'armature (+ Canplast, GC et BAT : courbes d'évolution pour tuyaux de drainage PVC `A1, A2, A3`, canalisation PE `D1, D3, D4, D8` et canalisation PP `F5`, les autres familles restent en tableau), 3 produits finis
KBOB (listes `PRODUCTS` : GC = béton frais, carrelets, tuyaux plastique, non-tissés ; BAT = ciment, béton frais, planches,
bitume d'étanchéité, tuyaux plastique, isolant), 4 recommandations (règle automatique ±3 % sur 3 mois, pas de prévision
inventée). Aucun prix fournisseur ni prix confidentiel. Ajouter un indicateur = l'ajouter dans `buildSpec`.

## Langues de l'interface (drapeaux FR / ES / IT / PT / EN)

`public/i18n.js` (moteur) + `public/i18n_dict.js` / `i18n_dict_categories.js` (dictionnaires, colonnes
`[fr, en, es, it, pt]`), chargés en dernier dans `catalogue.html`. Le français reste le texte source : la page
n'est PAS réécrite, les nœuds texte et les attributs `placeholder`/`title`/`alt` sont traduits au vol (y compris
le contenu construit par `innerHTML`, via `MutationObserver`) ; 🇫🇷 restitue l'original. Choix mémorisé
(`localStorage.eshopLang`), drapeaux SVG `public/flags/*.svg` (les emoji-drapeaux ne s'affichent pas sous Windows),
posés à droite de la barre de recherche. Trois niveaux : `E` = texte entier, `P` = motifs avec capture `$1`
(phrases à valeurs variables, ex. « 12 articles · … »), `F` = fragments (à éviter : risque de toucher des noms
d'articles). Une liste « A · B · C » est traduite élément par élément. **Un nouveau texte d'interface en français =
une ligne dans le dictionnaire**, sinon il reste en français dans les autres langues (aucune erreur). Restent
volontairement en français : noms d'articles/descriptifs, bon de commande PDF et e-mails fournisseurs (`textarea`,
valeurs saisies, `buildOrderHtml`), pages `/admin`, modules admin/analyse de marché. Un `translate="no"` exclut un bloc.

## Deploy workflow (always follow this exact sequence)

**Déploiement automatique** : une fois les vérifications faites, déployer sur `main` sans attendre de « pousse »/« déploie » du propriétaire — sauf si une validation de sa part est nécessaire (choix ambigu, action risquée ou irréversible, données à confirmer).

1. Edit, then run the full test suite: `bin/rails test` (must be 0
   failures/errors before committing).
2. For any `public/catalogue.html` change, also run the JS syntax-check
   snippet above, and prefer a quick Playwright smoke test for anything
   UI/flow-related (log in as a throwaway seeded user, drive the page,
   screenshot, clean up the seeded data afterward).
3. `git add -A && git commit` with a descriptive French message.
4. `git push -u origin claude/reprise-eshop-induni-2klf95`.
5. `git fetch origin main && git merge-base --is-ancestor origin/main HEAD`
   — if this fails, someone pushed to `main` independently (has happened via
   direct GitHub-web uploads); merge `origin/main` into the branch first,
   don't force-push.
6. `git push origin claude/reprise-eshop-induni-2klf95:main` — Railway
   auto-deploys from `main`. Any new migration runs automatically on
   deploy, but always run `bin/rails db:migrate` locally first to verify it
   applies cleanly.

## Local verification pattern

`bin/rails server -p 3099 -e development -d` to start a background dev
server; seed one-off test users/data via a scratch `.rb` file passed to
`bin/rails runner <file>` (embedding multi-line Ruby directly in a bash `-e`
string reliably fails with cryptic Bundler errors — always use a file);
drive with a Python Playwright script
(`executable_path='/opt/pw-browsers/chromium'`); screenshot and read via the
Read tool; then clean up seeded users/products/orders and
`pkill -f "puma 8.0.2.*ESHOP-INDUNI"` before finishing.
