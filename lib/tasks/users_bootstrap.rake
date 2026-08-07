namespace :users do
  # Safety net for the same failure mode fixed in lib/tasks/catalog_seed.rake:
  # if the production database is ever recreated empty, db:prepare's
  # schema-load shortcut brings back the table structure but no data at
  # all — including the admin account, which (unlike suppliers/products/
  # chantiers) has no seed source to replay it from, since db/seeds.rb
  # deliberately refuses to run in production. No-op unless
  # BOOTSTRAP_ADMIN_EMAIL/BOOTSTRAP_ADMIN_PASSWORD are set in Railway
  # variables, so it never creates an account nobody asked for.
  desc "Idempotently ensure a bootstrap admin account exists (no-op unless BOOTSTRAP_ADMIN_EMAIL/PASSWORD are set)"
  task ensure_admin: :environment do
    email = ENV["BOOTSTRAP_ADMIN_EMAIL"].presence
    password = ENV["BOOTSTRAP_ADMIN_PASSWORD"].presence

    if email && password
      user = User.find_or_initialize_by(email: email.downcase)
      creating = user.new_record?
      user.first_name = user.first_name.presence || "Admin"
      user.last_name  = user.last_name.presence || "Induni"
      user.admin = true
      # Always sync the password from the env var, not just on creation:
      # this is a controlled recovery account, so changing
      # BOOTSTRAP_ADMIN_PASSWORD in Railway and redeploying must reliably
      # update it, even after the account already exists.
      user.password = password
      user.password_confirmation = password
      user.save!
      puts "users:ensure_admin — #{user.email} (#{creating ? 'créé' : 'mot de passe et statut admin synchronisés'})"
    else
      puts "users:ensure_admin — ignoré (BOOTSTRAP_ADMIN_EMAIL/BOOTSTRAP_ADMIN_PASSWORD non définis)"
    end
  end
end
