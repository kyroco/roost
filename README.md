# Roost

One registration per app, for Phoenix umbrella projects.

An app in an umbrella registers itself once. Its one registration names everything it brings to the host web app: its LiveView pages, the links that lead to them, and its settings. When the app is in the release, all of it shows. When it is not, none of it shows, and its pages answer 404 instead of crashing.

The host never names an app. The same build can then ship more than one release, each carrying a different set of apps.

Roost is below version 1.0. Its shape may still change.

## How it works

Roost follows the pattern Phoenix LiveDashboard uses. The app brings its pages, and the host's one router writes them in when it is built. A page therefore sits in the host's own `live_session`, behind the host's sign-in checks and layout. Moving between it and the host's other pages in that session needs no reload.

1. Each app registers its pages, links and settings as plain data in a `roost.exs` file in its own folder.
2. The host's config imports every such file.
3. The host's router calls `roost_pages/1` inside a `live_session`, which writes in every page registered to that session.
4. At run time, `Roost.links/1` and `Roost.settings/0` return only what the apps in the running release bring. `Roost.Plug` answers 404 for a page whose app is not there.

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

- `pages` lists `{live_session, path, live_view}`. Each page is written into the host's `live_session` of that name.
- `links` lists `{place, label, path}`. Each is a link the host draws at a named place, such as a menu.
- `settings` lists `{key, label, default}`. The setting's value is the app's own application env under `key`, or the default.

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

### 5. Put the app in the release

The host does not depend on its apps, so a release carries an app only if the release lists it:

```elixir
releases: [
  web: [applications: [my_app_web: :permanent, reports: :permanent]]
]
```

Leave the app out of a release, and its pages, links and settings are gone from that release.

## Things to know

- The host compiles before the apps that depend on it. `roost_pages/1` tells the compiler to expect the page modules, so a build with `--warnings-as-errors` passes.
- The router reads registrations when it compiles. After you change a registration, recompile the host.
- An app is "in the release" while it is loaded. A release loads every app it lists at boot.
- Run tests from the umbrella root. From inside the host app's folder, an app the host does not depend on is not loaded.

## Not yet

Registrations do not yet cover page panels (named places on a host page that an app fills), background jobs or database migrations.

## License

Apache-2.0. See [LICENSE](LICENSE).
