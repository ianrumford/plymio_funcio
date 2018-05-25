defmodule Plymio.Funcio.Map.Pattern do
  @moduledoc ~S"""
  Map Patterns.

  See `Plymio.Funcio` for an overview and documentation terms.
  """

  use Plymio.Funcio.Attribute

  @type error :: Plymio.Funcio.error()
  @type fun1_map :: Plymio.Funcio.fun1_map()

  import Plymio.Fontais.Error,
    only: [
      new_argument_error_result: 1
    ]

  import Plymio.Fontais.Result,
    only: [
      normalise1_result: 1
    ]

  import Plymio.Funcio.Map.Utility,
    only: [
      normalise_map1_funs: 1
    ]

  @doc false

  @since "0.1.0"

  @spec normalise0_reduce_while_result(any) :: {:cont, any} | {:halt, {:error, error}}

  def normalise0_reduce_while_result(value) do
    value
    |> case do
      {:error, %{__struct__: _}} = result ->
        {:halt, result}

      {:ok, value} ->
        {:cont, value}

      x ->
        x
        |> Exception.exception?()
        |> case do
          true ->
            {:halt, {:error, x}}

          _ ->
            {:halt, new_argument_error_result(m: "pattern0 result invalid", v: x)}
        end
    end
  end

  @doc ~S"""
  `apply1_map1_funs/1` takes a value and a *map/1*.

  It reduces the *map/1* and the reduced map/1 to the value returning `{:ok, transformed_value}`.

  Each *map/1* function can return `{:ok, value}`, `{:error, error}` or `value`. In the last case, the `value` is treated as `{:ok, value}` and the reduce_while continues.

  The reduce is halted if any function returns an `{:error, error}` result, returning the result.

  ## Examples

      iex> fun1 = fn v -> v end
      ...> 42 |> apply1_map1_funs(fun1)
      {:ok, 42}

      iex> fun1 = fn v -> v + 1 end
      iex> fun2 = fn v -> v * v end
      iex> fun3 = fn v -> v - 1 end
      ...> 42 |> apply1_map1_funs([fun1, fun2, fun3])
      {:ok, 1848}

      iex> fun1 = fn v -> v + 1 end
      iex> fun2 = fn v -> {:error, %ArgumentError{message: "value is #{v}"}} end
      iex> fun3 = fn v -> v - 1 end
      ...> {:error, error} = 42 |> apply1_map1_funs([fun1, fun2, fun3])
      ...> error |> Exception.message
      "value is 43"

      iex> fun1 = fn k,v -> {k,v} end
      ...> {:error, error} = 42 |> apply1_map1_funs(fun1)
      ...> error |> Exception.message |> String.starts_with?("map/1 function invalid")
      true

      iex> fun1 = [fn k,v -> {k,v} end, fn _k,v -> v end]
      ...> {:error, error} = 42 |> apply1_map1_funs(fun1)
      ...> error |> Exception.message |> String.starts_with?("map/1 function invalid")
      true

  """

  @since "0.1.0"

  @spec apply1_map1_funs(any) :: {:ok, fun1_map} | {:error, error}

  def apply1_map1_funs(value, funs \\ [])

  def apply1_map1_funs(value, funs) do
    with {:ok, fun} <- funs |> reduce1_map1_funs do
      value |> fun.()
    else
      {:error, %{__exception__: true}} = result -> result
    end
  end

  @doc ~S"""
  `reduce1_map1_funs/1` takes a *map/1* and reduces it to a
  single map/1 function that will return either `{:ok, any}` or
  `{:error, error}`.

  Each function in the *map/1* must be *pattern*1 compatible i.e. can return
  either `{:ok, any}`, `{:error, error}`, or `value`.

  ## Examples

      iex> fun1 = fn v -> v end
      ...> {:ok, fun} = fun1 |> reduce1_map1_funs
      ...> 42 |> fun.()
      {:ok, 42}

      iex> fun1 = fn v -> v + 1 end
      ...> fun2 = fn v -> {:ok, v * v} end
      ...> fun3 = fn v -> v - 1 end
      ...> {:ok, fun} = [fun1, fun2, fun3] |> reduce1_map1_funs
      ...> 42 |> fun.()
      {:ok, 1848}

      iex> fun1 = fn v -> v + 1 end
      ...> fun2 = fn v -> {:error, %ArgumentError{message: "value is #{v}"}} end
      ...> fun3 = fn v -> v - 1 end
      ...> {:ok, fun} = [fun1, fun2, fun3] |> reduce1_map1_funs
      ...> {:error, error} = 42 |> fun.()
      ...> error |> Exception.message
      "value is 43"

      iex> fun1 = fn k,v -> {k,v} end
      ...> {:error, error} = fun1 |> reduce1_map1_funs
      ...> error |> Exception.message |> String.starts_with?("map/1 function invalid")
      true

      iex> fun1 = [fn k,v -> {k,v} end, fn _k,v -> v end]
      ...> {:error, error} = fun1 |> reduce1_map1_funs
      ...> error |> Exception.message |> String.starts_with?("map/1 function invalid")
      true

  """

  @since "0.1.0"

  @spec reduce1_map1_funs(any) :: {:ok, fun1_map} | {:error, error}

  def reduce1_map1_funs(funs \\ [])

  def reduce1_map1_funs([]) do
    {:ok, &normalise1_result/1}
  end

  def reduce1_map1_funs(funs) do
    with {:ok, funs} <- funs |> normalise_map1_funs do
      fun = fn value ->
        funs
        |> Enum.reduce_while(
          value,
          fn f, v ->
            v
            |> f.()
            |> case do
              {:error, %{__struct__: _}} = result -> {:halt, result}
              {:ok, value} -> {:cont, value}
              value -> {:cont, value}
            end
          end
        )
        |> case do
          {:error, %{__struct__: _}} = result -> result
          value -> {:ok, value}
        end
      end

      {:ok, fun}
    else
      {:error, %{__exception__: true}} = result -> result
    end
  end
end
