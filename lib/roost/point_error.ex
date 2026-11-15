defmodule Roost.PointError do
  @moduledoc """
  Raised by `Roost.Point.check!/1` when a declared point or an app's `provides` breaks a rule,
  naming every problem it found, so a release refuses to start instead of failing at a call.
  """

  defexception [:problems]

  @impl true
  def message(%{problems: problems}) do
    "the points this release declares and the apps that fill them disagree:\n" <>
      Enum.map_join(problems, "\n", &("  * " <> &1))
  end
end
