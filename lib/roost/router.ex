defmodule Roost.Router do
  @moduledoc """
  Writes registered pages into the host's router.

  Call `roost_pages/1` inside a `live_session` of the host's router:

      import Roost.Router, only: [roost_pages: 1]

      live_session :main, on_mount: [MyAppWeb.RequireSignIn] do
        live "/account", AccountLive
        roost_pages(:main)
      end

  Every page registered to that `live_session` is written in, for every registered app, because
  one build serves every release. Each page goes through `Roost.Plug`, which answers 404 when its
  app is not in the running release.

  The host is compiled before the apps that depend on it, so the page modules do not exist yet
  when the router compiles. The macro tells the compiler to expect them
  (`@compile {:no_warn_undefined, ...}`), so a build that treats warnings as errors still passes.

  Registrations are read when the router compiles, so a change to one recompiles the router only
  when the host's configuration changes; `mix compile --force` after editing a registration.
  """

  @doc "Writes in the pages registered to `live_session`."
  defmacro roost_pages(live_session) when is_atom(live_session) do
    pages =
      for {_app, registration} <- Roost.registered(),
          {^live_session, path, live_view} <- Keyword.get(registration, :pages, []),
          do: {path, live_view}

    routes =
      for {path, live_view} <- pages, do: quote(do: live(unquote(path), unquote(live_view)))

    quote do
      @compile {:no_warn_undefined, unquote(Enum.map(pages, &elem(&1, 1)))}

      scope "/", alias: false do
        pipe_through(Roost.Plug)
        unquote_splicing(routes)
      end
    end
  end
end
