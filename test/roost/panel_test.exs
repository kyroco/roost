defmodule Roost.PanelTest do
  use ExUnit.Case, async: true

  import Phoenix.ConnTest

  @endpoint Roost.Test.Endpoint

  describe "panels/1" do
    test "returns the panels present apps register for a place" do
      assert Roost.panels(:host_top) == [
               %{app: :roost, place: :host_top, component: Roost.Test.PresentPanel}
             ]
    end

    test "leaves out a panel whose app is not in the release" do
      assert Roost.panels(:host_bottom) == []
    end

    test "returns nothing for a place no app fills" do
      assert Roost.panels(:nobody_fills_this) == []
    end
  end

  describe "a host page's named places" do
    setup do
      %{html: html_response(get(build_conn(), "/host"), 200)}
    end

    test "a place a present app fills shows its panel, with the host's context", %{html: html} do
      assert html =~ ~s(<div id="present-panel">A panel for Ada (in host_top\)</div>)
    end

    test "a place only an absent app fills shows nothing, and no error", %{html: html} do
      assert html =~ ~r{<div id="bottom">\s*</div>}
    end

    test "a place no app fills shows nothing", %{html: html} do
      assert html =~ ~r{<div id="unused">\s*</div>}
    end
  end
end
