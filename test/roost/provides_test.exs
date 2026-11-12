defmodule Roost.ProvidesTest do
  use ExUnit.Case, async: true

  describe "provider/1" do
    test "returns the module a present app provides under a name" do
      assert Roost.provider(:greeter) == Roost.Test.Greeter
    end

    test "returns nil for a name only an app not in the release provides" do
      assert Roost.provider(:absent_greeter) == nil
    end

    test "returns nil for a name a present app provides with a module not in the release" do
      assert Roost.provider(:missing_module) == nil
    end

    test "returns nil for a name no app provides" do
      assert Roost.provider(:nobody_provides_this) == nil
    end

    test "refuses a name two apps provide, naming both, whether or not each is in the release" do
      error = assert_raise ArgumentError, fn -> Roost.provider(:shared) end

      assert error.message =~ ":shared"
      assert error.message =~ ":roost (Roost.Test.Greeter)"
      assert error.message =~ ":not_in_release (Roost.Test.AbsentGreeter)"
    end
  end

  test "the provided module answers the host's call" do
    assert Roost.provider(:greeter).greet("Ada") == "Hello, Ada"
  end
end
