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

## Deploy workflow (always follow this exact sequence)

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
