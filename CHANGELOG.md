# Changelog

## 0.6.0

- A link may carry options: `{place, label, path, opts}` registers a keyword list, such as an icon or a line of text, that the host reads as it draws the link. `Roost.links/1` now returns `opts` on every link, `[]` for the three-element form, which is unchanged.

## 0.5.0

- Controller routes: a registration names `routes: [{scope, verb, path, controller, action}]`, and the host writes them into its own scope with `Roost.Router.roost_routes/1`. Each runs the host's pipeline for that scope and then `Roost.Plug`, so a route whose app is not in the running release answers 404.

## 0.4.0

- A page may carry a live action: `{live_session, path, live_view, action}` opens the page with that action, as Phoenix's `live/3` does, so one page module can serve several paths. The three-element form is unchanged.

## 0.3.0

- Background jobs: a registration names Oban crontab entries under `:jobs`, and `Roost.jobs/0` returns those whose worker is in the running release, for the host to add to its schedule.
- Migrations: a registration names `{repo, path}` under `:migrations`, and `Roost.migrations/1` returns each present app's folder for a repo, for the host to run after its own.
- `Roost.load_registered/0` loads the registered apps a release carries, for tasks run with `eval`.
- Phoenix, Phoenix LiveView and Plug are now optional. Without them, `Roost.Panel` and `Roost.Plug` are not compiled, and the rest works.

## 0.2.0

- Page panels: a registration names `panels: [{place, live_component}]`, and a host page marks a named place with `Roost.Panel.place/1`. Each panel renders as a live component with the host's `:context` and the `:place` name. A place no app in the running release fills renders nothing.
- `Roost.panels/1` returns the panels that fill a place.

## 0.1.0

- One registration per app, as plain data under `config :roost, :apps`: pages, links and settings.
- `Roost.Router.roost_pages/1` writes registered pages into the host's `live_session`.
- `Roost.Plug` answers 404 for a page whose app is not in the running release.
- `Roost.links/1` and `Roost.settings/0` return only what the apps in the running release bring.
