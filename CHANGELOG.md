# Changelog

## 0.1.0

- One registration per app, as plain data under `config :roost, :apps`: pages, links and settings.
- `Roost.Router.roost_pages/1` writes registered pages into the host's `live_session`.
- `Roost.Plug` answers 404 for a page whose app is not in the running release.
- `Roost.links/1` and `Roost.settings/0` return only what the apps in the running release bring.
