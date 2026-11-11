defmodule Roost.RoutesTest do
  use ExUnit.Case, async: true

  import Phoenix.ConnTest

  @endpoint Roost.Test.Endpoint

  test "a registered route of a present app is written in and answers" do
    assert response(get(build_conn(), "/present-route"), 200) == "A route an app brings"
    assert response(post(build_conn(), "/present-route"), 201) == "Made by a route an app brings"
  end

  test "a registered route of an app not in the release answers 404, with no error" do
    assert response(get(build_conn(), "/absent-route"), 404) == "Not Found"
  end

  test "a registered route sits in the host's scope, behind its pipeline and Roost.Plug" do
    route = Phoenix.Router.route_info(Roost.Test.Router, "GET", "/present-route", "localhost")

    assert route.plug == Roost.Test.PresentController
    assert route.plug_opts == :show
    assert :browser in route.pipe_through
    assert Roost.Plug in route.pipe_through
  end

  test "the host's own routes in the same scope are untouched" do
    assert response(get(build_conn(), "/host-route"), 200) == "A route an app brings"
  end

  test "the router compiles without warnings for a controller that does not exist" do
    refute Code.ensure_loaded?(Roost.Test.AbsentController)
  end
end
