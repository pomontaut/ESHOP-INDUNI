namespace :users do
  # A fresh/reset database (e.g. Railway Postgres volume recreated) has no
  # users at all: nobody can log in, so `current_user` is nil for everyone,
  # which makes both the admin nav link and the per-user chantiers list
  # vanish (Api::SessionsController#me returns admin:false / no chantiers
  # key when logged out) — looking exactly like they "disappeared" from the
  # tool. Until now the only recovery path was manually hitting
  # /setup/admin?token=... after every such reset. Run this on every boot,
  # right after catalog:seed, so the admin account is restored automatically
  # whenever ADMIN_EMAIL/ADMIN_PASSWORD are configured, without ever
  # touching an admin account that already exists.
  desc "Idempotently ensure the configured admin account exists (no-op if already present or unconfigured)"
  task ensure_admin: :environment do
    email    = ENV["ADMIN_EMAIL"].presence
    password = ENV["ADMIN_PASSWORD"].presence

    if !email || !password
      puts "users:ensure_admin — ADMIN_EMAIL/ADMIN_PASSWORD not set, skipping"
      next
    end

    if User.exists?(email: email.downcase)
      puts "users:ensure_admin — #{email} already exists, leaving untouched"
      next
    end

    user = User.new(
      email: email,
      first_name: ENV["ADMIN_FIRST_NAME"].presence || "Admin",
      last_name: ENV["ADMIN_LAST_NAME"].presence || "Induni",
      password: password,
      admin: true,
      must_change_password: false
    )

    if user.save
      puts "users:ensure_admin — created admin account #{email}"
    else
      puts "users:ensure_admin — could not create #{email}: #{user.errors.full_messages.join(', ')}"
    end
  end
end
