defmodule Roost.Test.PresentLive do
  @moduledoc false
  use Phoenix.LiveView

  @impl Phoenix.LiveView
  def render(assigns), do: ~H"<p id='present-page'>A page an app brings</p>"
end

defmodule Roost.Test.PresentPanel do
  @moduledoc false
  use Phoenix.LiveComponent

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div id="present-panel">A panel for {@context.who} (in {@place})</div>
    """
  end
end

defmodule Roost.Test.HostLive do
  @moduledoc false
  use Phoenix.LiveView

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <p id="host-page">The host's own page</p>
    <div id="top"><Roost.Panel.place name={:host_top} context={%{who: "Ada"}} /></div>
    <div id="bottom"><Roost.Panel.place name={:host_bottom} /></div>
    <div id="unused"><Roost.Panel.place name={:nobody_fills_this} /></div>
    """
  end
end

defmodule Roost.Test.Router do
  @moduledoc false
  use Phoenix.Router

  import Phoenix.LiveView.Router
  import Roost.Router, only: [roost_pages: 1]

  pipeline :browser do
    plug :fetch_session
  end

  scope "/" do
    pipe_through :browser

    live_session :main do
      live "/host", Roost.Test.HostLive
      roost_pages(:main)
    end
  end
end

defmodule Roost.Test.Endpoint do
  @moduledoc false
  use Phoenix.Endpoint, otp_app: :roost

  plug Plug.Session, store: :cookie, key: "_roost_test", signing_salt: "roost-test-session"
  plug Roost.Test.Router
end
