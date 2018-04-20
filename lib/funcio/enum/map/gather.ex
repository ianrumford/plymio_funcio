defmodule Plymio.Funcio.Enum.Map.Gather do
  @moduledoc ~S"""
  Map and Gather Patterns for Enumerables.

  These functions map the elements of an *enum* and gather the
  results according to one of the defined *patterns*.

  Gathering means collecting all the `:ok` and `:error` results into a
  *opts* with keys `:ok` and `:error`. The value of each key will be a list
  of 2tuples where the first element is the *enum* element and the
  second is either the `value` from {`:ok, value}` or `error` from
  `{:error, error}`. If there are no `:ok` or `:error` results, the
  key will not be present in the final *opts*.

  See `Plymio.Funcio` for overview and documentation terms.
  """

  use Plymio.Funcio.Attribute

  @type error :: Plymio.Funcio.error()
  @type stream :: Plymio.Funcio.stream()
  @type opts :: Plymio.Funcio.opts()

  import Plymio.Funcio.Error,
    only: [
      new_error_result: 1
    ]

  import Plymio.Fontais.Result,
    only: [
      normalise0_result: 1
    ],
    warn: false

  import Plymio.Funcio.Map.Utility,
    only: [
      reduce_map1_funs: 1
    ]

  @doc ~S"""
  `map_gather0_enum/2` take an *enum* and *map/1* and applies
  the *map/1* to each element of the *enum* and then gathers the results according to *pattern 0*.

  ## Examples

      iex> fun = fn v -> {:ok, v * v} end
      ...> [1,2,3] |> map_gather0_enum(fun)
      {:ok, [ok: [{1,1},{2,4},{3,9}]]}

      iex> fun = fn
      ...>  3 -> {:error, %ArgumentError{message: "argument is 3"}}
      ...>  v -> {:ok, v + 42}
      ...> end
      ...> [1,2,3] |> map_gather0_enum(fun)
      {:ok, [ok: [{1,43},{2,44}], error: [{3, %ArgumentError{message: "argument is 3"}}]]}

      iex> fun = :not_a_fun
      ...> {:error, error} = [1,2,3] |> map_gather0_enum(fun)
      ...> error |> Exception.message
      "map/1 function invalid, got: :not_a_fun"

      iex> fun = fn v -> {:ok, v} end
      ...> {:error, error} = 42 |> map_gather0_enum(fun)
      ...> error |> Exception.message
      ...> |> String.starts_with?("protocol Enumerable not implemented for 42")
      true

  """

  @since "0.1.0"

  @spec map_gather0_enum(any, any) :: {:ok, opts} | {:error, error}

  def map_gather0_enum(enum, fun) do
    with {:ok, fun} <- [fun, &normalise0_result/1] |> reduce_map1_funs do
      try do
        enum
        |> Enum.reduce_while({[], []}, fn element, {oks, errors} ->
          element
          |> fun.()
          |> case do
            {:error, %{__struct__: _} = error} ->
              {:cont, {oks, [{element, error} | errors]}}

            {:ok, value} ->
              {:cont, {[{element, value} | oks], errors}}

            value ->
              with {:error, error} <- new_error_result(m: "pattern0 result invalid", v: value) do
                {:cont, {oks, [{element, error} | errors]}}
              else
                {:error, %{__struct__: _}} = result -> {:halt, result}
              end
          end
        end)
        |> case do
          {:error, %{__exception__: true}} = result -> result
          {oks, []} -> {:ok, [ok: oks |> Enum.reverse()]}
          {[], errors} -> {:ok, [error: errors |> Enum.reverse()]}
          {oks, errors} -> {:ok, [ok: oks |> Enum.reverse(), error: errors |> Enum.reverse()]}
        end
      rescue
        error ->
          {:error, error}
      end
    else
      {:error, %{__exception__: true}} = result -> result
    end
  end
end
