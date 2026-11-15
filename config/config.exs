import Config

if config_env() == :test do
  # Two registrations: this library's own app, which is loaded in its tests, and an app that
  # is not in the release, whose page module does not exist.
  config :roost, :apps,
    roost: [
      pages: [
        {:main, "/present", Roost.Test.PresentLive},
        {:main, "/present/other", Roost.Test.PresentLive, :other}
      ],
      routes: [
        {:main, :get, "/present-route", Roost.Test.PresentController, :show},
        {:main, :post, "/present-route", Roost.Test.PresentController, :create}
      ],
      links: [
        {:sidebar, "Present page", "/present"},
        {:footer, "Help", "/help"},
        {:footer, "Status", "/status", icon: "signal", blurb: "Is it up"}
      ],
      settings: [{:greeting, "Greeting the page shows", "hello"}],
      panels: [{:host_top, Roost.Test.PresentPanel}],
      jobs: [
        {"0 3 * * *", Roost.Test.NightlyWorker},
        {"*/5 * * * *", Roost.Test.NightlyWorker, queue: :maintenance}
      ],
      migrations: [{Roost.Test.Repo, "priv/repo/migrations"}],
      provides: [
        {:greeter, Roost.Test.Greeter},
        {:missing_module, Roost.Test.NoSuchModule},
        {:shared, Roost.Test.Greeter},
        {:greetings, Roost.Test.Greeter},
        {:greetings, Roost.Test.OtherGreeter}
      ]
    ],
    not_in_release: [
      pages: [{:main, "/absent", Roost.Test.AbsentLive}],
      routes: [{:main, :get, "/absent-route", Roost.Test.AbsentController, :show}],
      links: [{:sidebar, "Absent page", "/absent"}],
      settings: [{:absent_setting, "A setting nobody sees", 1}],
      panels: [{:host_top, Roost.Test.AbsentPanel}, {:host_bottom, Roost.Test.AbsentPanel}],
      jobs: [{"* * * * *", Roost.Test.AbsentWorker}],
      migrations: [{Roost.Test.Repo, "priv/repo/migrations"}],
      provides: [
        {:absent_greeter, Roost.Test.AbsentGreeter},
        {:shared, Roost.Test.AbsentGreeter},
        {:greetings, Roost.Test.AbsentGreeter}
      ]
    ]

  # The points the host of these tests declares: one an app fills, one only an absent app fills,
  # one several apps fill, and one that is required.
  config :roost, :points,
    greeter: [behaviour: Roost.Test.Greeting, stand_in: Roost.Test.SilentGreeter],
    absent_greeter: [behaviour: Roost.Test.Greeting, stand_in: Roost.Test.SilentGreeter],
    greetings: [behaviour: Roost.Test.Greeting, many: true],
    must_greet: [behaviour: Roost.Test.Greeting, required: true]

  config :roost, Roost.Test.Endpoint,
    secret_key_base: String.duplicate("a", 64),
    live_view: [signing_salt: "roost-test-salt"],
    server: false

  config :phoenix, :json_library, Jason
end

config :logger, level: :warning
