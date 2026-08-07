# Sans expire_after, le cookie de session par défaut de Rails meurt à la
# fermeture du navigateur — ce qui obligeait à se reconnecter très souvent
# sans lien réel avec les redéploiements de l'application.
Rails.application.config.session_store :cookie_store, key: "_eshop_induni_session", expire_after: 90.days
