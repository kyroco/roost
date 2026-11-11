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

  @doc """
  Writes in the controller routes registered to `scope`, inside the host's own `scope` block, so
  each runs the host's pipeline for that scope and then `Roost.Plug`, which answers 404 when the
  route's app is not in the running release.
  """
  defmacro roost_routes(scope) when is_atom(scope) do
    routes =
      for {_app, registration} <- Roost.registered(),
          {^scope, verb, path, controller, action} <- Keyword.get(registration, :routes, []),
          do: {verb, path, controller, action}

    written =
      for {verb, path, controller, action} <- routes do
        {verb, [],
         [path, controller, action, [private: Macro.escape(%{roost_module: controller})]]}
      end

    quote do
      @compile {:no_warn_undefined, unquote(routes |> Enum.map(&elem(&1, 2)) |> Enum.uniq())}

      scope "/", alias: false do
        pipe_through(Roost.Plug)
        unquote_splicing(written)
      end
    end
  end

  @doc "Writes in the pages registered to `live_session`."
  defmacro roost_pages(live_session) when is_atom(live_session) do
    pages =
      for {_app, registration} <- Roost.registered(),
          page <- Keyword.get(registration, :pages, []),
          elem(page, 0) == live_session,
          do: page_route(page)

    routes =
      for {path, live_view, action} <- pages do
        if action,
          do: quote(do: live(unquote(path), unquote(live_view), unquote(action))),
          else: quote(do: live(unquote(path), unquote(live_view)))
      end

    quote do
      @compile {:no_warn_undefined, unquote(Enum.map(pages, &elem(&1, 1)) |> Enum.uniq())}

      scope "/", alias: false do
        pipe_through(Roost.Plug)
        unquote_splicing(routes)
      end
    end
  end

  # A page is {live_session, path, live_view}, or {live_session, path, live_view, action} for a
  # page that opens with that live action, as Phoenix's own `live/3` takes it.
  defp page_route({_live_session, path, live_view}), do: {path, live_view, nil}

  defp page_route({_live_session, path, live_view, action}) when is_atom(action),
    do: {path, live_view, action}
end
