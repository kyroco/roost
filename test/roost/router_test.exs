defmodule Roost.RouterTest do
  use ExUnit.Case, async: true

  import Phoenix.ConnTest

  @endpoint Roost.Test.Endpoint

  test "a registered page of a present app is written in and renders" do
    conn = get(build_conn(), "/present")

    assert html_response(conn, 200) =~ "A page an app brings"
  end

  test "a registered page with an action opens the page with that live action" do
    conn = get(build_conn(), "/present/other")

    assert html_response(conn, 200) =~ "A page an app brings, as other"

    route = Enum.find(Phoenix.Router.routes(Roost.Test.Router), &(&1.path == "/present/other"))
    assert elem(route.metadata.phoenix_live_view, 1) == :other
  end

  test "a registered page with no action opens with no live action" do
    assert html_response(get(build_conn(), "/present"), 200) =~ "A page an app brings, as index"
  end

  test "a registered page of an app not in the release answers 404, with no error" do
    conn = get(build_conn(), "/absent")

    assert response(conn, 404) == "Not Found"
  end

  test "the host's own pages in the same live_session are untouched" do
    assert html_response(get(build_conn(), "/host"), 200) =~ "The host's own page"
  end

  test "a registered page sits in the live_session the registration names" do
    routes = Phoenix.Router.routes(Roost.Test.Router)
    present = Enum.find(routes, &(&1.path == "/present"))
    host = Enum.find(routes, &(&1.path == "/host"))

    assert elem(present.metadata.phoenix_live_view, 0) == Roost.Test.PresentLive
    assert live_session(present) == live_session(host)
  end

  test "the router compiles without warnings for a page module that does not exist" do
    assert Code.ensure_loaded?(Roost.Test.Router)
    refute Code.ensure_loaded?(Roost.Test.AbsentLive)
  end

  defp live_session(route), do: route.metadata.phoenix_live_view |> elem(3) |> Map.get(:name)
end
