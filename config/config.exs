use Mix.Config

config :unsub, Unsub.Mailer,
  adapter: Bamboo.SMTPAdapter,
  server: "smtp.gmail.com",
  port: 587,
  username: System.get_env("SMTP_USERNAME"),
  password: System.get_env("SMTP_PASSWORD"),
  tls: :if_available,
  allowed_tls_versions: [:tlsv1, :"tlsv1.1", :"tlsv1.2"],
  ssl: false,
  retries: 1

config :stripity_stripe, api_key: System.get_env("STRIPE_SECRET_KEY")
