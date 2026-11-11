defmodule RoostTest do
  use ExUnit.Case, async: true

  describe "registered/0 and present/0" do
    test "registered/0 returns every registration, present or not" do
      assert Keyword.keys(Roost.registered()) == [:roost, :not_in_release]
    end

    test "present/0 returns only the apps in the running release" do
      assert Keyword.keys(Roost.present()) == [:roost]
    end

    test "present?/1 is true for a loaded app and false for one that is not" do
      assert Roost.present?(:roost)
      refute Roost.present?(:not_in_release)
    end
  end

  describe "links/1" do
    test "returns the links present apps bring to a place, and none from an absent app" do
      assert Roost.links(:sidebar) == [
               %{app: :roost, label: "Present page", path: "/present", opts: []}
             ]
    end

    test "returns only the links for the place asked" do
      assert [%{label: "Help"}, %{label: "Status"}] = Roost.links(:footer)
      assert Roost.links(:nowhere) == []
    end

    test "a link registered with options carries them, in order with three-element links" do
      assert Roost.links(:footer) == [
               %{app: :roost, label: "Help", path: "/help", opts: []},
               %{
                 app: :roost,
                 label: "Status",
                 path: "/status",
                 opts: [icon: "signal", blurb: "Is it up"]
               }
             ]
    end
  end

  describe "settings/0" do
    test "returns the settings present apps bring, with their default value" do
      assert Roost.settings() == [
               %{app: :roost, key: :greeting, label: "Greeting the page shows", value: "hello"}
             ]
    end

    test "a value set in the app's own env replaces the default" do
      Application.put_env(:roost, :greeting, "good morning")
      on_exit(fn -> Application.delete_env(:roost, :greeting) end)

      assert [%{key: :greeting, value: "good morning"}] = Roost.settings()
    end
  end
end
