if Code.ensure_loaded?(Phoenix.Component) do
  defmodule Roost.Panel do
    @moduledoc """
    Named places on a host page that apps fill with panels.

    The host marks a place on a LiveView page and passes whatever the panels need:

        <Roost.Panel.place name={:account_page} context={%{account_id: @account_id}} />

    An app fills it through its registration, with a `Phoenix.LiveComponent`:

        config :roost, :apps,
          my_app: [panels: [{:account_page, MyApp.AccountPanel}]]

    Each panel is rendered as a live component, so it keeps its own state and handles its own
    events. It receives two assigns: `:context`, the map the host passed, and `:place`, the place's
    name. A place no app in the running release fills renders nothing.
    """

    use Phoenix.Component

    @doc "Renders every panel that fills the place `name`, or nothing."
    attr :name, :atom, required: true, doc: "the place's name, as registrations name it"
    attr :context, :map, default: %{}, doc: "what the host passes to each panel"

    def place(assigns) do
      assigns = assign(assigns, :panels, Roost.panels(assigns.name))

      ~H"""
      <.live_component
        :for={panel <- @panels}
        module={panel.component}
        id={"roost-#{@name}-#{panel.app}"}
        place={@name}
        context={@context}
      />
      """
    end
  end
end
