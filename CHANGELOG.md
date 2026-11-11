# Changelog

## 0.2.0

- Page panels: a registration names `panels: [{place, live_component}]`, and a host page marks a named place with `Roost.Panel.place/1`. Each panel renders as a live component with the host's `:context` and the `:place` name. A place no app in the running release fills renders nothing.
- `Roost.panels/1` returns the panels that fill a place.

## 0.1.0

- One registration per app, as plain data under `config :roost, :apps`: pages, links and settings.
- `Roost.Router.roost_pages/1` writes registered pages into the host's `live_session`.
- `Roost.Plug` answers 404 for a page whose app is not in the running release.
- `Roost.links/1` and `Roost.settings/0` return only what the apps in the running release bring.
