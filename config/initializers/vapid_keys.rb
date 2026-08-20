# VAPID key pair identifying this server to push services (no third-party
# account needed, unlike SMS — this is the free/standard Web Push
# protocol). The fallback pair below is fine to keep as-is (VAPID keys
# aren't a secret the way an API key is — they only ever authenticate this
# server to push services, never grant access to anything), but each
# deployment can override it via Railway env vars if desired.
Rails.application.config.x.vapid_public_key =
  ENV.fetch("VAPID_PUBLIC_KEY", "BPQf8IebkYYpFnZn5EjjWY54dGQptYNZjPxef8rbL1MBGAe7LUOJqOLoTtX4mJN-aHCEe736ffXbsNDqSMnwAjU")
Rails.application.config.x.vapid_private_key =
  ENV.fetch("VAPID_PRIVATE_KEY", "MUwDY0u18DjTMWauK2cETabIu3-lRZLGq8BFZsr36zU")
