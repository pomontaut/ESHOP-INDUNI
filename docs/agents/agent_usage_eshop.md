# Agent d'usage de l'e-shop (administrateur seulement)

Objectif : voir si les utilisateurs se connectent, si la recherche d'un article leur est difficile, combien
de temps / de clics / de requêtes il leur faut avant de mettre un article au panier, et par quel moyen ils
le trouvent. Méthode déterministe (aucun appel à un modèle), mesures réelles uniquement.

**Périmètre.** Tous les utilisateurs SAUF les administrateurs et le service achats (`User#usage_tracked?` :
`portail_achat_access?` = admin, ACHETEUR, secteur SERVICE ACHATS, et toute fonction contenant « ACHAT »).
Le filtre est appliqué côté serveur (`Api::UsageController#events` ignore les autres) et côté navigateur
(`/api/me` → `usage_tracking`). Aucun prix, aucun contenu de commande.

**Mesures** (navigateur, dernier `<script>` de `catalogue.html`, jeton d'onglet conservé 30 min) :
- ouverture de l'e-shop (`visit`) et connexion explicite (`login`, écran de login) ;
- temps actif = secondes où l'onglet est visible ET une interaction a eu lieu < 60 s ;
- chaque clic (`click`, avec le moyen), chaque changement d'écran (`nav` : vue / catalogue / famille / sous-famille),
  chaque mot tapé dans la barre de recherche après 1,2 s sans frappe (`search`, avec le nombre de résultats),
  chaque ajout au panier (`add_to_cart`, avec le moyen et la requête en cours) ;
- **moyen** : `recherche` (barre de recherche), `liste` (entonnoir : fil d'Ariane, listes, menus),
  `image` (tuiles / photos). Classement par l'élément cliqué : heuristique.

**Parcours** (`UsageReport.stats_for`) : du premier clic / écran / mot tapé jusqu'à l'ajout au panier
(ou jusqu'à la fin de la session : « sans ajout »). Durée, clics, mots tapés dans l'ordre (le premier compte),
moyen utilisé. Difficulté repérée : parcours > 5 min ou > 15 clics [H], recherches sans résultat (mot clef
ou synonyme à ajouter), connecté sans aucun ajout au panier, utilisateurs suivis non connectés.

**Compte rendu quotidien.** `UsageReport.run_due!` (thread Puma, `config/puma.rb`, contrôle toutes les 10 min) :
à partir de 18h30 (Zurich), une fois par jour, seulement s'il y a eu de l'activité, e-mail à
`User::PERMANENT_ADMIN_EMAILS` (`UsageMailer#daily_report`) et archivage (`usage_reports`). Désactivable :
`USAGE_REPORT_AUTO=false`. Écran « 🕵️ Agent d'usage » (Admin, `/api/usage/report?date=`) : même contenu,
détail des parcours par utilisateur, envoi manuel. Données conservées 90 jours.

**Limites** : un utilisateur sans l'e-shop ouvert n'est pas mesuré ; le temps réel passé hors onglet n'est pas
connu ; le moyen « image / liste » est déduit du clic, pas d'une intention déclarée.
