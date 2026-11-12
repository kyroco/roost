# Roost

One registration per app, for Phoenix umbrella projects.

An app in an umbrella registers itself once. Its one registration names everything it brings to the host web app: its LiveView pages, the links that lead to them, its settings, the panels it puts on the host's pages, its scheduled jobs, its database migrations and the modules it provides for the host to call. When the app is in the release, all of it shows. When it is not, none of it shows, and its pages answer 404 instead of crashing.

The host never names an app. The same build can then ship more than one release, each carrying a different set of apps.

Roost is below version 1.0. Its shape may still change.

## How it works

Roost follows the pattern Phoenix LiveDashboard uses. The app brings its pages, and the host's one router writes them in when it is built. A page therefore sits in the host's own `live_session`, behind the host's sign-in checks and layout. Moving between it and the host's other pages in that session needs no reload.

1. Each app registers its pages, links, settings, panels, jobs and migrations as plain data in a `roost.exs` file in its own folder.
2. The host's config imports every such file.
3. The host's router calls `roost_pages/1` inside a `live_session`, which writes in every page registered to that session.
4. At run time, `Roost.links/1` and `Roost.settings/0` return only what the apps in the running release bring. A named place on a host page (`Roost.Panel.place/1`) shows only their panels. `Roost.Plug` answers 404 for a page whose app is not there.

## Installation

```elixir
def deps do
  [
    {:roost, github: "kyroco/roost", ref: "<commit>"}
  ]
end
```

## Usage

### 1. Register an app

In the app's folder, for example `apps/reports/roost.exs`:

```elixir
import Config

config :roost, :apps,
  reports: [
    pages: [{:main, "/reports", Reports.IndexLive}],
    links: [{:sidebar, "Reports", "/reports"}],
    settings: [{:report_limit, "Reports kept per account", 100}]
  ]
```

- `pages` lists `{live_session, path, live_view}`. Each page is written into the host's `live_session` of that name. Add a fourth element, `{live_session, path, live_view, action}`, to open the page with that live action, the way Phoenix's `live/3` does, so one page module can serve several paths.
- `routes` lists `{scope, verb, path, controller, action}`. Each is a controller route, such as a form post or a file, that the host writes into its own scope of that name with `roost_routes/1`, behind that scope's pipeline and `Roost.Plug`.
- `links` lists `{place, label, path}`. Each is a link the host draws at a named place, such as a menu. Add a fourth element, `{place, label, path, opts}`, to give the host a keyword list it reads as it draws the link, such as `icon: "chart"`; every link `Roost.links/1` returns carries `opts`, `[]` when none were given.
- `settings` lists `{key, label, default}`. The setting's value is the app's own application env under `key`, or the default.
- `provides` lists `{name, module}`. Each is a module the host calls under a name it knows; see step 7.

### 2. Read every registration in the host's config

In the umbrella's `config/config.exs`:

```elixir
for registration <- Path.wildcard(Path.expand("../apps/*/roost.exs", __DIR__)) do
  import_config registration
end
```

### 3. Write the pages into the host's router

```elixir
import Roost.Router, only: [roost_pages: 1]

live_session :main, on_mount: [MyAppWeb.RequireSignIn] do
  live "/account", MyAppWeb.AccountLive
  roost_pages(:main)
end
```

### 4. Show links and settings

```heex
<.link :for={link <- Roost.links(:sidebar)} navigate={link.path}>{link.label}</.link>
```

```heex
<dl>
  <%= for setting <- Roost.settings() do %>
    <dt>{setting.label}</dt>
    <dd>{setting.value}</dd>
  <% end %>
</dl>
```

### 5. Fill named places with panels

A host page marks a named place and passes what the panels need:

```heex
<Roost.Panel.place name={:account_page} context={%{account_id: @account_id}} />
```

An app fills it with a `Phoenix.LiveComponent`, named in its registration:

```elixir
config :roost, :apps,
  reports: [panels: [{:account_page, Reports.AccountPanel}]]
```

Each panel is rendered as a live component, so it keeps its own state and handles its own events. It receives `:context`, the map the host passed, and `:place`, the place's name. A place no app in the running release fills renders nothing, and no error.

### 6. Schedule jobs and run migrations

An app names its scheduled jobs as Oban crontab entries, and its migrations folder for a repo:

```elixir
config :roost, :apps,
  reports: [
    jobs: [{"0 3 * * *", Reports.NightlyWorker}],
    migrations: [{MyApp.Repo, "priv/repo/migrations"}]
  ]
```

The host adds `Roost.jobs()` to its Oban cron plugin's `:crontab` before Oban starts. It runs its own migrations first, then each folder from `Roost.migrations(repo)`:

```elixir
Roost.load_registered()

for path <- Roost.migrations(MyApp.Repo) do
  Ecto.Migrator.run(MyApp.Repo, path, :up, all: true)
end
```

Roost does not depend on Oban or Ecto; jobs and migrations are plain data the host hands to them.

### 7. Call a module an app provides

When host code needs an app to do something and hand back an answer, the app provides a module under a name the host knows:

```elixir
config :roost, :apps,
  reports: [provides: [{:report_builder, Reports.Builder}]]
```

The host asks for whoever provides that name, and does without when no app in the release does:

```elixir
case Roost.provider(:report_builder) do
  nil -> {:error, :no_reports}
  builder -> builder.build(account)
end
```

One name has one provider. Two registrations providing the same name raise `ArgumentError`, naming both, whether or not each app is in the release, so the clash shows in every build.

### 8. Put the app in the release

The host does not depend on its apps, so a release carries an app only if the release lists it:

```elixir
releases: [
  web: [applications: [my_app_web: :permanent, reports: :permanent]]
]
```

Leave the app out of a release, and its pages, links, settings, panels, jobs, migrations and provided modules are gone from that release.

## Things to know

- The host compiles before the apps that depend on it. `roost_pages/1` tells the compiler to expect the page modules, so a build with `--warnings-as-errors` passes.
- The router reads registrations when it compiles. After you change a registration, recompile the host.
- An app is "in the release" while it is loaded. A release loads every app it lists at boot.
- Run tests from the umbrella root. From inside the host app's folder, an app the host does not depend on is not loaded.

## Optional dependencies

Phoenix, Phoenix LiveView and Plug are optional dependencies. A host app that only runs jobs and migrations does not need them; without them, `Roost.Panel` and `Roost.Plug` are not compiled.

## License

Apache-2.0. See [LICENSE](LICENSE).
