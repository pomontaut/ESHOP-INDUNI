class Api::SessionsController < ApplicationController
  skip_before_action :require_login
  skip_before_action :verify_authenticity_token

  def me
    if current_user
      test_profile = Api::TestProfilesController.active_profile(session, current_user)
      # Environnement test (admin) : on ne montre que le bandeau d'un profil
      # chantier (contremaître / conducteur de travaux), sans droits admin.
      dev_mode = test_profile == Api::TestProfilesController::DEV_PROFILE
      return render json: test_profile_payload(test_profile) if test_profile && !dev_mode

      render json: {
        logged_in:         true,
        real_admin:        current_user.admin?,
        test_profile:      (test_profile if dev_mode),
        dev_mode:          dev_mode,
        is_owner:          User::PERMANENT_ADMIN_EMAILS.include?(current_user.email.to_s.downcase),
        testRecipient:     (Api::TestProfilesController::TEST_RECIPIENT if test_profile),
        admin:             current_user.admin?,
        full_name:         current_user.full_name,
        email:             current_user.email,
        phone:             current_user.phone,
        sector:            current_user.sector,
        can_create_users:  current_user.effective_can_create_users?,
        can_create_orders: current_user.effective_can_create_orders?,
        can_modify_orders: current_user.effective_can_modify_orders?,
        can_import_quote:  current_user.effective_can_import_quote?,
        can_generic_order: current_user.effective_can_generic_order?,
        can_view_dashboard:    current_user.effective_can_view_dashboard?,
        can_validate_orders:   current_user.effective_can_validate_orders?,
        can_enable_alerts:     current_user.effective_can_enable_alerts?,
        can_view_analysis:     current_user.effective_can_view_analysis?,
        can_view_market_indices:      current_user.effective_can_view_market_indices?,
        can_view_intelligence_buying: current_user.effective_can_view_intelligence_buying?,
        can_view_nomenclature: current_user.effective_can_view_nomenclature?,
        usage_tracking:    current_user.usage_tracked?,
        # Date réelle de la dernière modification d'un article (tarif, prix…),
        # et non la date du fichier catalogue.html (= date du dernier déploiement).
        catalogLastUpdated: (Product.maximum(:updated_at) || File.mtime(Rails.root.join("public/catalogue.html"))).strftime("%d.%m.%Y"),
        vapidPublicKey:    Rails.application.config.x.vapid_public_key,
        pushSubscribed:    current_user.push_subscriptions.exists?,
        supplierEmailsByCanton: Supplier.all.each_with_object({}) { |s, h|
          per_canton = Supplier::CANTONS.each_with_object({}) { |c, ch|
            email = s.public_send("email_#{c.downcase}")
            ch[c] = email if email.present?
          }
          h[s.name] = per_canton if per_canton.any?
        },
        # E-mail par défaut réellement configuré sur la fiche fournisseur
        # (Admin > Fournisseurs) — le client ne doit jamais retomber sur une
        # adresse figée dans catalogue.html si celle-ci existe.
        supplierDefaultEmails: Supplier.where.not(email: [ nil, "" ]).pluck(:name, :email).to_h,
        supplierExtraEmails: Supplier.where.not(email_secondaire: [ nil, "" ]).pluck(:name, :email_secondaire).to_h,
        allowed_suppliers: current_user.effective_visible_suppliers - (dev_mode ? [] : Supplier::TEST_ONLY_NAMES),
        # Cantons auxquels un fournisseur est réservé (ex. Tinguely = VAUD) :
        # contrôlé côté navigateur avant l'envoi d'une commande.
        supplierVisibleCantons: Supplier.all.select { |s| s.visible_cantons.present? }.to_h { |s| [ s.name, s.visible_cantons ] },
        chantiers:         Chantier.visible_to(current_user).includes(:contacts).order(:nom).map { |c|
          {
            nom:         c.nom,
            adresse:     c.adresse,
            npa:         c.npa,
            ville:       c.ville,
            contact:     c.contremaitre,
            telephone:   c.natel_contremaitre,
            contactLivraison:   c.contact_livraison,
            telephoneLivraison: c.natel_livraison,
            emailTechnicien: c.email_technicien,
            technicien:  c.technicien,
            natelTechnicien: c.natel_technicien,
            contraintes: c.contraintes_acces,
            consortium:  c.consortium,
            canton:      c.canton
          }.merge(c.team_json)
        }
      }
    else
      render json: { logged_in: false, admin: false, allowed_suppliers: [] }
    end
  end

  private

  def test_profile_payload(profile)
    {
      logged_in:         true,
      real_admin:        true,
      test_profile:      profile,
      testRecipient:     Api::TestProfilesController::TEST_RECIPIENT,
      admin:             false,
      full_name:         current_user.full_name,
      email:             current_user.email,
      phone:             current_user.phone,
      sector:            current_user.sector,
      can_create_users:  false,
      can_create_orders: true,
      can_modify_orders: false,
      can_import_quote:  false,
      can_generic_order: false,
      can_view_dashboard:    [ "Contremaître", Api::TestProfilesController::TRAINING_PROFILE ].include?(profile),
      can_validate_orders:   false,
      can_enable_alerts:     false,
      can_view_analysis:     false,
      can_view_market_indices:      false,
      can_view_intelligence_buying: false,
      can_view_nomenclature: false,
      catalogLastUpdated: (Product.maximum(:updated_at) || File.mtime(Rails.root.join("public/catalogue.html"))).strftime("%d.%m.%Y"),
      vapidPublicKey:    Rails.application.config.x.vapid_public_key,
      pushSubscribed:    current_user.push_subscriptions.exists?,
      supplierEmailsByCanton: {},
      supplierDefaultEmails: Supplier.where.not(email: [ nil, "" ]).pluck(:name, :email).to_h,
      supplierExtraEmails: Supplier.where.not(email_secondaire: [ nil, "" ]).pluck(:name, :email_secondaire).to_h,
      allowed_suppliers: current_user.effective_visible_suppliers,
      chantiers:         Chantier.visible_to(current_user).includes(:contacts).order(:nom).map { |c|
        {
          nom: c.nom, adresse: c.adresse, npa: c.npa, ville: c.ville,
          contact: c.contremaitre, telephone: c.natel_contremaitre,
          contactLivraison: c.contact_livraison, telephoneLivraison: c.natel_livraison,
          emailTechnicien: c.email_technicien, technicien: c.technicien, natelTechnicien: c.natel_technicien, contraintes: c.contraintes_acces, consortium: c.consortium, canton: c.canton
        }.merge(c.team_json)
      }
    }
  end
end
