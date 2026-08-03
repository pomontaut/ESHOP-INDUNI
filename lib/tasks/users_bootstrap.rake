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
      if creating
        user.password = password
        user.password_confirmation = password
      end
      user.save!
      puts "users:ensure_admin — #{user.email} (#{creating ? 'créé' : 'statut admin garanti'})"
    else
      puts "users:ensure_admin — ignoré (BOOTSTRAP_ADMIN_EMAIL/BOOTSTRAP_ADMIN_PASSWORD non définis)"
    end
  end
end
