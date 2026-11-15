defmodule Roost.PointTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureIO

  alias Roost.Point

  @greeting Roost.Test.Greeting
  @present [:host, :billing, :sign_up]
  defp present?(app), do: app in @present

  defp problems(points, registered, opts \\ []),
    do: Point.problems(points, registered, &present?/1, opts)

  describe "point/1" do
    test "returns the module a present app provides at a declared point" do
      assert Roost.point(:greeter) == Roost.Test.Greeter
      assert Roost.point(:greeter).greet("Ada") == "Hello, Ada"
    end

    test "returns the point's stand-in when only an app not in the release provides it" do
      assert Roost.point(:absent_greeter) == Roost.Test.SilentGreeter
      assert Roost.point(:absent_greeter).greet("Ada") == ""
    end

    test "refuses a name the host does not declare" do
      error = assert_raise ArgumentError, fn -> Roost.point(:nobody_declares_this) end
      assert error.message =~ ":nobody_declares_this is not a point the host declares"
    end

    test "refuses a required point no app in the release fills" do
      error = assert_raise ArgumentError, fn -> Roost.point(:must_greet) end
      assert error.message =~ "point :must_greet is required"
    end

    test "refuses a point that takes several providers" do
      assert_raise ArgumentError, ~r/ask providers\/1/, fn -> Roost.point(:greetings) end
    end
  end

  describe "providers/1" do
    test "returns every module present apps provide at a many point, leaving out absent ones" do
      assert Roost.providers(:greetings) == [Roost.Test.Greeter, Roost.Test.OtherGreeter]
    end

    test "refuses a point that takes one provider" do
      assert_raise ArgumentError, ~r/ask point\/1/, fn -> Roost.providers(:greeter) end
    end
  end

  describe "problems/4" do
    test "finds none when every provider fills a declared point with every call" do
      points = [greeter: [behaviour: @greeting, stand_in: Roost.Test.SilentGreeter]]
      registered = [billing: [provides: [greeter: Roost.Test.Greeter]]]

      assert problems(points, registered) == []
    end

    test "refuses a provides name the host does not declare, so an app cannot invent a point" do
      registered = [billing: [provides: [invented: Roost.Test.Greeter]]]

      assert problems([], registered) == [
               ":billing provides :invented (Roost.Test.Greeter), a point the host does not declare"
             ]
    end

    test "lets through an undeclared name the host allows by name" do
      registered = [billing: [provides: [invented: Roost.Test.Greeter]]]

      assert problems([], registered, allow_undeclared: [:invented]) == []
    end

    test "refuses a provider module that is not loaded, as a rename leaves it" do
      points = [greeter: [behaviour: @greeting, stand_in: Roost.Test.SilentGreeter]]
      registered = [billing: [provides: [greeter: Roost.Test.RenamedAway]]]

      assert problems(points, registered) == [
               ":billing provides :greeter with Roost.Test.RenamedAway, which is not loaded"
             ]
    end

    test "refuses a provider that does not declare the point's behaviour" do
      points = [greeter: [behaviour: @greeting, stand_in: Roost.Test.SilentGreeter]]
      registered = [billing: [provides: [greeter: Roost.Test.UndeclaredGreeter]]]

      assert problems(points, registered) == [
               ":billing provides :greeter with Roost.Test.UndeclaredGreeter, which does not " <>
                 "declare @behaviour Roost.Test.Greeting"
             ]
    end

    test "refuses a provider that lacks one of the point's calls, naming the call" do
      module = compile_half_greeter()
      points = [greeter: [behaviour: @greeting, stand_in: Roost.Test.SilentGreeter]]
      registered = [billing: [provides: [greeter: module]]]

      assert problems(points, registered) == [
               ":billing's provider of :greeter, #{inspect(module)}, lacks wave/0"
             ]
    end

    test "does not hold an app that is not in the release to its providers' modules" do
      points = [greeter: [behaviour: @greeting, stand_in: Roost.Test.SilentGreeter]]
      registered = [not_built: [provides: [greeter: Roost.Test.NeverBuilt]]]

      assert problems(points, registered) == []
    end

    test "refuses a required point that no app in the release fills" do
      points = [greeter: [behaviour: @greeting, required: true]]
      registered = [not_built: [provides: [greeter: Roost.Test.NeverBuilt]]]

      assert problems(points, registered) == [
               "point :greeter is required and no app in the release provides it"
             ]
    end

    test "refuses two providers at a point that takes one, whether or not each is in the release" do
      points = [greeter: [behaviour: @greeting, stand_in: Roost.Test.SilentGreeter]]

      registered = [
        billing: [provides: [greeter: Roost.Test.Greeter]],
        not_built: [provides: [greeter: Roost.Test.NeverBuilt]]
      ]

      assert problems(points, registered) == [
               "point :greeter takes one provider and is provided by :billing " <>
                 "(Roost.Test.Greeter), :not_built (Roost.Test.NeverBuilt)"
             ]
    end

    test "lets several apps fill a many point" do
      points = [greetings: [behaviour: @greeting, many: true]]

      registered = [
        billing: [provides: [greetings: Roost.Test.Greeter]],
        sign_up: [provides: [greetings: Roost.Test.OtherGreeter]]
      ]

      assert problems(points, registered) == []
    end

    test "refuses a declaration with neither a stand-in nor required, or with both" do
      points = [
        bare: [behaviour: @greeting],
        both: [behaviour: @greeting, stand_in: Roost.Test.SilentGreeter, required: true]
      ]

      assert problems(points, []) == [
               "point :bare has neither a stand-in nor required: true",
               "point :both has both a stand-in and required: true; it takes one or the other",
               "point :both is required and no app in the release provides it"
             ]
    end

    test "refuses a behaviour that is not one, and a stand-in that is missing" do
      points = [
        not_one: [behaviour: Roost.Test.NotABehaviour, stand_in: Roost.Test.SilentGreeter],
        gone: [behaviour: @greeting, stand_in: Roost.Test.GoneStandIn]
      ]

      assert problems(points, []) == [
               "point :not_one names Roost.Test.NotABehaviour as its behaviour, which is not a " <>
                 "loaded behaviour",
               "the stand-in of point :gone, Roost.Test.GoneStandIn, is not loaded"
             ]
    end

    test "refuses a stand-in that lacks one of the point's calls" do
      module = compile_half_greeter()
      points = [thin: [behaviour: @greeting, stand_in: module]]

      assert problems(points, []) == [
               "the stand-in of point :thin, #{inspect(module)}, lacks wave/0"
             ]
    end

    test "does not count an optional call as missing" do
      assert Point.missing_calls(Roost.Test.Greeter, @greeting) == []
    end
  end

  describe "check!/1" do
    test "raises naming every problem in the configured points and registrations" do
      error = assert_raise Roost.PointError, fn -> Point.check!() end

      assert Exception.message(error) =~
               ":roost provides :missing_module (Roost.Test.NoSuchModule), a point the host does not declare"

      assert Exception.message(error) =~
               "point :must_greet is required and no app in the release provides it"
    end

    test "leaves out a name the host allows undeclared" do
      error =
        assert_raise Roost.PointError, fn ->
          Point.check!(allow_undeclared: [:missing_module, :shared])
        end

      refute Exception.message(error) =~ ":missing_module"
      assert Exception.message(error) =~ ":must_greet"
    end
  end

  # A provider that declares the behaviour and lost a call, compiled here so the compiler's own
  # warning about it stays out of the test output.
  defp compile_half_greeter do
    module = Module.concat(Roost.Test, "HalfGreeter#{System.unique_integer([:positive])}")

    capture_io(:stderr, fn ->
      Code.compile_quoted(
        quote do
          defmodule unquote(module) do
            @behaviour Roost.Test.Greeting
            def greet(name), do: "Hey, " <> name
          end
        end
      )
    end)

    module
  end
end
