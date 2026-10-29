# Agent « moteur de recherche » (chat administrateur)

Objectif : faire progresser le bandeau de recherche (le « moteur de recherche ») pour que les utilisateurs
trouvent plus vite. Chat réservé aux administrateurs (bouton « 🔎 Agent recherche », en bas à gauche) ;
`SearchAgent`. **Compréhension du français libre** (remarques, questions « pourquoi ? », consignes) par l'API Claude
(`SearchAgent::Brain`, modèle `SEARCH_AGENT_MODEL`, défaut `claude-sonnet-5-5`, clé `ANTHROPIC_API_KEY` du serveur, déjà utilisée par l'import de devis) :
l'agent appelle des outils (synonymes, mots clefs, règles de classement, bilan, suggestions) et APPLIQUE les remarques. Sans clé ou
en cas d'erreur API, repli sur des commandes à formulation fixe (et le chat le dit).

**Mémoire de recherche** (`SearchMemory`, appliquée immédiatement à tous les utilisateurs) :
- synonymes : « synonyme : culotte = embranchement, raccord en Y » (dans les deux sens) ou
  « quand on tape siphon de cour, il faut trouver avaloir » (un sens). Servis par `/api/search_memory`,
  injectés dans `SEARCH_SYNONYM_MAP_V49` au chargement (`srchApplySynonyms`) ;
- mots clefs d'un article : « ajoute les mots clefs raccord en Y pour 381100018 » (n° INDUNI = toutes les lignes
  fournisseur de l'article, référence fournisseur, ou nom de l'article ; plusieurs candidats → l'agent demande de
  préciser). Fusionnés avec les mots clefs de la nomenclature dans `induniKeywords` de `/api/products` ;
- « mémoire » liste, « oublie 12 » / « oublie culotte » supprime.

**Retours de l'agent d'usage** (`UsageReport`) : « bilan » = qualité de la recherche sur 7 jours (recherches sans
résultat, requêtes et temps avant l'ajout au panier, parcours à 3 requêtes ou plus, moyen utilisé, mots sans
résultat). « suggestions » = mots clefs proposés d'après les parcours réels des 14 derniers jours : ce qui a été
tapé avant l'ajout d'un article au panier et ne figure pas dans le texte de cet article ; « valide 12 13 »,
« valide tout » ou « ignore 14 » (jamais reproposé).

**Test** : « teste tuyau drainage 125 » exécute le vrai moteur du navigateur (`scoreProductV49`) et montre les
5 premiers résultats. L'historique du chat est conservé (`search_agent_messages`).

**Limites** : pas de compréhension libre du langage (formulations ci-dessus) ; une suggestion n'est qu'une
proposition tant qu'elle n'est pas validée ; les synonymes ne changent pas le classement par pertinence mais
élargissent les mots recherchés.

**Règles de classement** (`SearchMemory` kind `rule`, `DEFAULT_RULES`, servies par `/api/search_memory` → `rules`, appliquées par
`srchRuleBonus` qui enveloppe `scoreProductV49`) : ajoutent des points au score d'un article qui contient un mot de
`product_has_any` (désignation, descriptif, familles), quand la requête contient un mot de `query_has_any` et aucun de
`query_lacks_any`. Intégrées : tube de drainage/perforé après les tuyaux pleins si la requête ne parle pas de drainage (-120) ;
structuré après le compact si la requête demande du compact (-100). L'administrateur en ajoute : « règle : pénalise drainage sauf
si on tape drain (-120) » (ou en français libre) ; « disable_rule » / « oublie m12 » les retire.

**« Pourquoi ? »** : à chaque message, le navigateur mesure le vrai moteur pour les requêtes citées (entre guillemets ou après
« tape / cherche ») et les articles visés (n° INDUNI ou référence) et envoie le contexte (`engine` : classement, scores, mots
retrouvés / absents / seulement par mots clefs, mots non demandés, règles) à l'agent (`srchEngineContext`, `srchWhy`).
