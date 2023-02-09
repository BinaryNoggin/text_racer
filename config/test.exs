import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :text_racer, TextRacerWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "zy02AJ790aaUp8zwlEBYAqYum3uhQUlQUyCg6PAkzqtqcgO+I4XEZHm7ypTVHGSI",
  server: false

# In test we don't send emails.
config :text_racer, TextRacer.Mailer, adapter: Swoosh.Adapters.Test

# Print only warnings and errors during test
config :logger, level: :warn

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
