defmodule Roost.Test.Greeting do
  @moduledoc false
  @callback greet(String.t()) :: String.t()
  @callback wave() :: :waved
  @callback bow() :: :bowed
  @optional_callbacks bow: 0
end

defmodule Roost.Test.SilentGreeter do
  @moduledoc false
  @behaviour Roost.Test.Greeting

  @impl true
  def greet(_name), do: ""

  @impl true
  def wave, do: :waved
end

defmodule Roost.Test.Greeter do
  @moduledoc false
  @behaviour Roost.Test.Greeting

  @impl true
  def greet(name), do: "Hello, " <> name

  @impl true
  def wave, do: :waved
end

defmodule Roost.Test.OtherGreeter do
  @moduledoc false
  @behaviour Roost.Test.Greeting

  @impl true
  def greet(name), do: "Hi, " <> name

  @impl true
  def wave, do: :waved
end

defmodule Roost.Test.UndeclaredGreeter do
  @moduledoc false
  def greet(name), do: "Yo, " <> name
  def wave, do: :waved
end

defmodule Roost.Test.NotABehaviour do
  @moduledoc false
end
