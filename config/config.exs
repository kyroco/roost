import Config

if config_env() == :test do
  # Two registrations: this library's own app, which is loaded in its tests, and an app that
  # is not in the release, whose page module does not exist.
  config :roost, :apps,
    roost: [
      pages: [{:main, "/present", Roost.Test.PresentLive}],
      links: [{:sidebar, "Present page", "/present"}, {:footer, "Help", "/help"}],
      settings: [{:greeting, "Greeting the page shows", "hello"}],
      panels: [{:host_top, Roost.Test.PresentPanel}],
      jobs: [
        {"0 3 * * *", Roost.Test.NightlyWorker},
        {"*/5 * * * *", Roost.Test.NightlyWorker, queue: :maintenance}
      ],
      migrations: [{Roost.Test.Repo, "priv/repo/migrations"}]
    ],
    not_in_release: [
      pages: [{:main, "/absent", Roost.Test.AbsentLive}],
      links: [{:sidebar, "Absent page", "/absent"}],
      settings: [{:absent_setting, "A setting nobody sees", 1}],
      panels: [{:host_top, Roost.Test.AbsentPanel}, {:host_bottom, Roost.Test.AbsentPanel}],
      jobs: [{"* * * * *", Roost.Test.AbsentWorker}],
      migrations: [{Roost.Test.Repo, "priv/repo/migrations"}]
    ]

  config :roost, Roost.Test.Endpoint,
    secret_key_base: String.duplicate("a", 64),
    live_view: [signing_salt: "roost-test-salt"],
    server: false

  config :phoenix, :json_library, Jason
end

config :logger, level: :warning
