if Code.ensure_loaded?(Plug) do
  defmodule Roost.Plug do
    @moduledoc """
    Answers 404 for a registered page or controller route whose app is not in the running release.

    It runs before Phoenix mounts the page, so a page whose module is not in the release never
    reaches the router's call into it, which would otherwise crash every request.
    """

    @behaviour Plug

    import Plug.Conn

    @impl Plug
    def init(opts), do: opts

    @impl Plug
    def call(%Plug.Conn{private: %{roost_module: module}} = conn, _opts) do
      if Roost.in_release?(module), do: conn, else: not_found(conn)
    end

    def call(%Plug.Conn{private: %{phoenix_live_view: route}} = conn, _opts) do
      if Roost.in_release?(elem(route, 0)), do: conn, else: not_found(conn)
    end

    def call(conn, _opts), do: conn

    defp not_found(conn) do
      conn
      |> put_resp_content_type("text/plain")
      |> send_resp(404, "Not Found")
      |> halt()
    end
  end
end
