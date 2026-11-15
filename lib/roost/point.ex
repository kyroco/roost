defmodule Roost.Point do
  @moduledoc """
  Points the host declares, and the check that holds every app's `provides` to them.

  A point is a name the host calls, declared once by the host under `config :roost, :points`:

      config :roost, :points,
        checkout: [behaviour: MyHost.Checkout, stand_in: MyHost.Checkout.None],
        payments: [behaviour: MyHost.Payments, required: true],
        account_deleted: [behaviour: MyHost.AccountDeleted, many: true]

    * `:behaviour` - the module whose callbacks are every call the host makes at the point and
      every answer it takes back. Each provider declares it with `@behaviour`, so the compiler
      names a call the provider lacks.
    * `:stand_in` - the module that answers when no app in the release fills the point. It
      implements the same behaviour, so leaving an app out gives the stand-in's answer, never a
      crash.
    * `required: true` - in place of a stand-in: the release refuses to start when no app in it
      fills the point.
    * `many: true` - several apps may fill the point, and `Roost.providers/1` returns them all.
      With none, the host gets an empty list, so a stand-in is not needed.

  An app's registration names a point it fills with `provides: [{name, module}]`. It can only
  fill a point the host declares: a name the host does not declare is refused at start, so an app
  cannot invent a point the host calls. `check!/1` runs these checks; call it when the host
  starts.
  """

  @typedoc "One point the host declares."
  @type declaration :: [
          behaviour: module(),
          stand_in: module(),
          required: boolean(),
          many: boolean()
        ]

  @doc "Returns every point the host declares, in the order declared."
  @spec declared() :: [{atom(), declaration()}]
  def declared, do: Application.get_env(:roost, :points, [])

  @doc """
  Checks the declared points and every registration's `provides` against them, and raises
  `Roost.PointError` naming every problem when there is one:

    * a point whose behaviour is not loaded, whose stand-in is missing or lacks a call, or that
      has both or neither of a stand-in and `required: true` (a `many` point may have neither);
    * a `provides` name the host does not declare, unless it is in the `:allow_undeclared` option;
    * two registrations filling a point that is not `many`;
    * a provider whose app is in the release but whose module is not loaded, does not declare the
      point's behaviour, or lacks one of its calls;
    * a required point no app in the release fills.

  Returns `:ok` when there is none.
  """
  @spec check!(keyword()) :: :ok
  def check!(opts \\ []) do
    case problems(declared(), Roost.registered(), &Roost.present?/1, opts) do
      [] -> :ok
      problems -> raise Roost.PointError, problems: problems
    end
  end

  @doc """
  The problems `check!/1` raises for, as sentences, given the declared points, the
  registrations, and a function that says whether an app is in the release.
  """
  @spec problems(
          [{atom(), declaration()}],
          [{atom(), Roost.registration()}],
          (atom() -> boolean()),
          keyword()
        ) :: [String.t()]
  def problems(points, registered, present?, opts \\ []) do
    allowed = Keyword.get(opts, :allow_undeclared, [])
    provided = provided(registered)

    Enum.flat_map(points, &declaration_problems/1) ++
      Enum.flat_map(provided, &undeclared(&1, points, allowed)) ++
      Enum.flat_map(points, &point_problems(&1, provided, present?))
  end

  defp provided(registered) do
    for {app, registration} <- registered,
        {name, module} <- Keyword.get(registration, :provides, []),
        do: {name, app, module}
  end

  defp declaration_problems({name, declaration}) do
    behaviour = declaration[:behaviour]
    stand_in = declaration[:stand_in]
    required = declaration[:required] == true
    many = declaration[:many] == true

    cond do
      not behaviour?(behaviour) ->
        [
          "point #{inspect(name)} names #{inspect(behaviour)} as its behaviour, which is not a loaded behaviour"
        ]

      stand_in && required ->
        [
          "point #{inspect(name)} has both a stand-in and required: true; it takes one or the other"
        ]

      is_nil(stand_in) and not required and not many ->
        ["point #{inspect(name)} has neither a stand-in nor required: true"]

      stand_in ->
        implementation_problems("the stand-in of point #{inspect(name)}", stand_in, behaviour)

      true ->
        []
    end
  end

  defp undeclared({name, app, module}, points, allowed) do
    if Keyword.has_key?(points, name) or name in allowed,
      do: [],
      else: [
        "#{inspect(app)} provides #{inspect(name)} (#{inspect(module)}), a point the host does not declare"
      ]
  end

  defp point_problems({name, declaration}, provided, present?) do
    providers = for {^name, app, module} <- provided, do: {app, module}
    present = Enum.filter(providers, fn {app, _module} -> present?.(app) end)

    shared(name, declaration, providers) ++
      Enum.flat_map(present, &provider_problems(&1, name, declaration[:behaviour])) ++
      unfilled(name, declaration, present)
  end

  defp shared(name, declaration, providers) when length(providers) > 1 do
    if declaration[:many] == true,
      do: [],
      else: [
        "point #{inspect(name)} takes one provider and is provided by " <>
          Enum.map_join(providers, ", ", fn {app, module} ->
            "#{inspect(app)} (#{inspect(module)})"
          end)
      ]
  end

  defp shared(_name, _declaration, _providers), do: []

  defp provider_problems({app, module}, name, behaviour) do
    cond do
      not behaviour?(behaviour) ->
        []

      not Code.ensure_loaded?(module) ->
        ["#{inspect(app)} provides #{inspect(name)} with #{inspect(module)}, which is not loaded"]

      behaviour not in declared_behaviours(module) ->
        [
          "#{inspect(app)} provides #{inspect(name)} with #{inspect(module)}, which does not declare @behaviour #{inspect(behaviour)}"
        ]

      true ->
        implementation_problems(
          "#{inspect(app)}'s provider of #{inspect(name)}",
          module,
          behaviour
        )
    end
  end

  defp unfilled(name, declaration, []) do
    if declaration[:required] == true,
      do: ["point #{inspect(name)} is required and no app in the release provides it"],
      else: []
  end

  defp unfilled(_name, _declaration, _present), do: []

  defp implementation_problems(what, module, behaviour) do
    if Code.ensure_loaded?(module) do
      case missing_calls(module, behaviour) do
        [] -> []
        missing -> ["#{what}, #{inspect(module)}, lacks #{Enum.map_join(missing, ", ", &call/1)}"]
      end
    else
      ["#{what}, #{inspect(module)}, is not loaded"]
    end
  end

  @doc false
  @spec missing_calls(module(), module()) :: [{atom(), arity()}]
  def missing_calls(module, behaviour) do
    optional = behaviour.behaviour_info(:optional_callbacks)

    for {fun, arity} = callback <- behaviour.behaviour_info(:callbacks),
        callback not in optional,
        not function_exported?(module, fun, arity),
        do: callback
  end

  defp behaviour?(module) do
    is_atom(module) and not is_nil(module) and Code.ensure_loaded?(module) and
      function_exported?(module, :behaviour_info, 1)
  end

  defp declared_behaviours(module) do
    module.module_info(:attributes) |> Keyword.get_values(:behaviour) |> List.flatten()
  end

  defp call({fun, arity}), do: "#{fun}/#{arity}"
end
