defmodule Roost do
  @moduledoc """
  One registration per app.

  An app registers itself once, as plain data, under the `:roost` application's `:apps` key,
  keyed by its own OTP application name:

      import Config

      config :roost, :apps,
        my_app: [
          pages: [{:main, "/reports", MyApp.ReportsLive}],
          links: [{:sidebar, "Reports", "/reports"}],
          settings: [{:report_limit, "Reports kept per account", 100}]
        ]

  Keep that in a file inside the app (for example `apps/my_app/roost.exs`) and have the host's
  `config/config.exs` import every such file, so the host never names an app:

      for registration <- Path.wildcard(Path.expand("../apps/*/roost.exs", __DIR__)) do
        import_config registration
      end

  The host's router writes every registered page in when it is built (`Roost.Router`). At run
  time a page, link or setting shows only while its app is in the running release
  (`present?/1`); a page whose app is absent answers 404 (`Roost.Plug`).

  ## A registration

    * `:pages` - `{live_session, path, live_view}`: the page is written into the host's
      `live_session` of that name, so live navigation to and from the host's other pages in it
      needs no reload. `{live_session, path, live_view, action}` opens the page with that live
      action, as Phoenix's `live/3` does, so one page module can serve several paths.
    * `:routes` - `{scope, verb, path, controller, action}`: a controller route the host writes
      into its own scope of that name with `Roost.Router.roost_routes/1`, behind that scope's
      pipeline, for a path that is not a LiveView page, such as a form post or a file.
    * `:links` - `{place, label, path}`: a link the host draws at a named place, such as a menu.
    * `:settings` - `{key, label, default}`: a setting the host shows. Its value is the app's own
      application env under `key`, else `default`.
    * `:panels` - `{place, live_component}`: a panel that fills a named place on a host page
      (`Roost.Panel.place/1`). A place no app fills shows nothing.
    * `:jobs` - Oban crontab entries, `{expression, worker}` or `{expression, worker, opts}`,
      that the host adds to its schedule (`jobs/0`).
    * `:migrations` - `{repo, path}`: a migrations folder inside the app that the host runs on
      `repo` after its own (`migrations/1`).
  """

  @typedoc "One app's registration."
  @type registration :: [
          pages: [{atom(), String.t(), module()} | {atom(), String.t(), module(), atom()}],
          routes: [{atom(), atom(), String.t(), module(), atom()}],
          links: [{atom(), String.t(), String.t()}],
          settings: [{atom(), String.t(), term()}],
          panels: [{atom(), module()}],
          jobs: [{String.t(), module()} | {String.t(), module(), keyword()}],
          migrations: [{module(), String.t()}]
        ]

  @typedoc "A link a present app brings to a place."
  @type link :: %{app: atom(), label: String.t(), path: String.t()}

  @typedoc "A panel that fills a named place on a host page."
  @type panel :: %{app: atom(), place: atom(), component: module()}

  @typedoc "A setting a present app brings, with its current value."
  @type setting :: %{app: atom(), key: atom(), label: String.t(), value: term()}

  @doc """
  Returns every registration the configuration holds, whether or not its app is in the release.
  """
  @spec registered() :: [{atom(), registration()}]
  def registered, do: Application.get_env(:roost, :apps, [])

  @doc "Returns the registrations of the apps in the running release."
  @spec present() :: [{atom(), registration()}]
  def present, do: Enum.filter(registered(), fn {app, _registration} -> present?(app) end)

  @doc """
  Returns true while `app` is loaded. In a release every app the release carries is loaded at
  boot, so this means the app is in the build.
  """
  @spec present?(atom()) :: boolean()
  def present?(app) when is_atom(app), do: Application.spec(app, :vsn) != nil

  @doc "Returns the links present apps bring to `place`, in registration order."
  @spec links(atom()) :: [link()]
  def links(place) when is_atom(place) do
    for {app, registration} <- present(),
        {^place, label, path} <- Keyword.get(registration, :links, []),
        do: %{app: app, label: label, path: path}
  end

  @doc """
  Returns the panels that fill `place`, in registration order, leaving out any whose component
  is not in the running release.
  """
  @spec panels(atom()) :: [panel()]
  def panels(place) when is_atom(place) do
    for {app, registration} <- registered(),
        {^place, component} <- Keyword.get(registration, :panels, []),
        in_release?(component),
        do: %{app: app, place: place, component: component}
  end

  @doc false
  @spec in_release?(module()) :: boolean()
  def in_release?(module) when is_atom(module) do
    case Application.get_application(module) do
      nil -> false
      app -> present?(app)
    end
  end

  @doc """
  Returns the scheduled jobs present apps register, as Oban crontab entries (`{expression,
  worker}` or `{expression, worker, opts}`), leaving out any whose worker is not in the running
  release. Add them to the host's Oban cron plugin's `:crontab` before Oban starts.
  """
  @spec jobs() :: [{String.t(), module()} | {String.t(), module(), keyword()}]
  def jobs do
    for {_app, registration} <- registered(),
        entry <- Keyword.get(registration, :jobs, []),
        in_release?(elem(entry, 1)),
        do: entry
  end

  @doc """
  Returns, for `repo`, the migrations folder of each present app that names it, as a full path
  inside that app. Run the host's own migrations first, then these, with
  `Ecto.Migrator.run(repo, path, :up, all: true)`.
  """
  @spec migrations(module()) :: [String.t()]
  def migrations(repo) when is_atom(repo) do
    for {app, registration} <- registered(),
        present?(app),
        {^repo, path} <- Keyword.get(registration, :migrations, []),
        do: Application.app_dir(app, path)
  end

  @doc """
  Loads every registered app the release carries, for a task that runs without starting the
  release (such as a migration step run with `eval`), so `present?/1` sees them.
  """
  @spec load_registered() :: :ok
  def load_registered do
    _ = Application.load(:roost)

    for {app, _registration} <- registered() do
      _ = Application.load(app)
    end

    :ok
  end

  @doc "Returns the settings present apps bring, each with its current value."
  @spec settings() :: [setting()]
  def settings do
    for {app, registration} <- present(),
        {key, label, default} <- Keyword.get(registration, :settings, []),
        do: %{app: app, key: key, label: label, value: Application.get_env(app, key, default)}
  end
end
