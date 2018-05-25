defmodule Plymio.Funcio.Enum.Reduce do
  @moduledoc ~S"""
  Reduce Functions for Enumerables.

  These functions reduce the elements of an *enum* according to one of the defined *patterns*.

  See `Plymio.Funcio` for overview and documentation terms.
  """

  use Plymio.Funcio.Attribute

  @type error :: Plymio.Funcio.error()

  import Plymio.Funcio.Error,
    only: [
      new_error_result: 1
    ]

  import Plymio.Fontais.Guard,
    only: [
      is_value_unset_or_nil: 1
    ]

  @doc ~S"""
  `reduce0_enum/2` takes an *enum*, the initial accumulator (`initial_s`) and an arity 2 function, and reduces the *enum* according to *pattern 0*.

  The arity 2 function is passed the current element from the *enum*
  and the accumulator (`s)`.

  If the result is `{:ok, s}` the `s` becomes the new accumulator.

  If the result is `{:error, error}` or `value` the reduction is
  halted, returning `{:error, error}`.

  The fianl result is either `{:ok, final_s}` or `{error, error}`.

  ## Examples

      iex> 0 .. 4 |>  reduce0_enum(0, fn v,s -> {:ok, s + v} end)
      {:ok, 10}

      iex> {:error, error} = 0 .. 4 |>  reduce0_enum(0, fn v,s -> s + v end)
      ...> error |> Exception.message
      "pattern0 result invalid, got: 0"

      iex> {:ok, map} = 0 .. 4
      ...> |> reduce0_enum(%{}, fn v,s -> {:ok, Map.put(s, v, v * v)} end)
      ...> map |> Map.to_list |> Enum.sort
      [{0, 0}, {1, 1}, {2, 4}, {3, 9}, {4, 16}]

      iex> {:error, error} = :not_an_enum
      ...> |> reduce0_enum(0, fn v,_s -> v end)
      ...> error |> Exception.message
      ...> |> String.starts_with?("protocol Enumerable not implemented for :not_an_enum")
      true

  """

  @since "0.1.0"

  @spec reduce0_enum(any, any, any) :: {:ok, any} | {:error, error}

  def reduce0_enum(enum, initial_accumulator, fun)

  def reduce0_enum(enum, init_acc, fun)
      when is_function(fun, 2) do
    try do
      enum
      |> Enum.reduce_while(
        init_acc,
        fn v, s ->
          fun.(v, s)
          |> case do
            {:ok, s} -> {:cont, s}
            {:error, %{__struct__: _}} = result -> {:halt, result}
            v -> {:halt, new_error_result(m: "pattern0 result invalid", v: v)}
          end
        end
      )
      |> case do
        {:error, %{__exception__: true}} = result -> result
        s -> {:ok, s}
      end
    rescue
      error ->
        {:error, error}
    end
  end

  def reduce0_enum(_enum, _init_acc, fun) do
    new_error_result(m: "map/2 function invalid", v: fun)
  end

  @doc ~S"""
  `reduce1_enum/2` takes an *enum*, the initial accumulator
  (`initial_s`) and an arity 2 function, and reduces the *enum*
  according to *pattern 1*.

  The arity 2 function is passed the current element from the *enum*
  and the accumulator (`s)`.

  If the result is `{:ok, s}` or `s`, the `s` becomes the new accumulator.

  If the result is `{:error, error}` the reduction is
  halted, returning the `{:error, error}`.

  The result is either `{:ok, final_s}` or `{error, error}`.

  ## Examples

      iex> 0 .. 4 |>  reduce1_enum(0, fn v,s -> s + v end)
      {:ok, 10}

      iex> {:ok, map} = 0 .. 4
      ...> |> reduce1_enum(%{}, fn v,s -> Map.put(s, v, v * v) end)
      ...> map |> Map.to_list |> Enum.sort
      [{0, 0}, {1, 1}, {2, 4}, {3, 9}, {4, 16}]

      iex> {:error, error} = :not_an_enum
      ...> |> reduce1_enum(0, fn v,_s -> v end)
      ...> error |> Exception.message
      ...> |> String.starts_with?("protocol Enumerable not implemented for :not_an_enum")
      true

  """

  @since "0.1.0"

  @spec reduce1_enum(any, any, any) :: {:ok, any} | {:error, error}

  def reduce1_enum(enum, initial_accumulator, fun)

  def reduce1_enum(enum, init_acc, fun)
      when is_function(fun, 2) do
    try do
      enum
      |> Enum.reduce_while(
        init_acc,
        fn v, s ->
          fun.(v, s)
          |> case do
            {:ok, s} -> {:cont, s}
            {:error, %{__struct__: _}} = result -> {:halt, result}
            s -> {:cont, s}
          end
        end
      )
      |> case do
        {:error, %{__exception__: true}} = result -> result
        s -> {:ok, s}
      end
    rescue
      error ->
        {:error, error}
    end
  end

  def reduce1_enum(_enum, _init_acc, fun) do
    new_error_result(m: "map/2 function invalid", v: fun)
  end

  @doc ~S"""
  `reduce2_enum/2` takes an *enum*, the initial accumulator
  (`initial_s`) and an arity 2 function, and reduces the *enum*
  according to *pattern 2*.

  The arity 2 function is passed the current element from the *enum*
  and the accumulator (`s)`.

  If the result is `nil` or [*the unset
  value*](https://hexdocs.pm/plymio_fontais/Plymio.Fontais.html#module-the-unset-value),
  `s` is unchanged.

  If the result is `{:ok, s}` or `s`, the `s` becomes the new
  accumulator.

  If the result is `{:error, error}` the reduction is halted,
  returning the `{:error, error}`.

  The result is either `{:ok, final_s}` or `{error, error}`.

  ## Examples

      iex> 0 .. 4 |>  reduce2_enum(0, fn v,s -> s + v end)
      {:ok, 10}

      iex> fun = fn
      ...>  3, _s -> {:error, %ArgumentError{message: "argument is 3"}}
      ...>  v, s -> {:ok, s + v}
      ...> end
      ...> {:error, error} = [1,2,3] |> reduce2_enum(0, fun)
      ...> error |> Exception.message
      "argument is 3"

      iex> fun = fn
      ...>  2, _s -> nil
      ...>  4, _s -> Plymio.Fontais.the_unset_value
      ...>  v, s -> {:ok, s + v}
      ...> end
      ...> [1,2,3,4,5] |> reduce2_enum(0, fun)
      {:ok, 9}

      iex> {:ok, map} = 0 .. 4
      ...> |> reduce2_enum(%{}, fn v,s -> Map.put(s, v, v * v) end)
      ...> map |> Map.to_list |> Enum.sort
      [{0, 0}, {1, 1}, {2, 4}, {3, 9}, {4, 16}]

      iex> {:error, error} = :not_an_enum
      ...> |> reduce2_enum(0, fn v,_s -> v end)
      ...> error |> Exception.message
      ...> |> String.starts_with?("protocol Enumerable not implemented for :not_an_enum")
      true

  """

  @since "0.1.0"

  @spec reduce2_enum(any, any, any) :: {:ok, any} | {:error, error}

  def reduce2_enum(enum, initial_accumulator, fun)

  def reduce2_enum(enum, init_acc, fun)
      when is_function(fun, 2) do
    try do
      enum
      |> Enum.reduce_while(
        init_acc,
        fn v, s ->
          fun.(v, s)
          |> case do
            x when is_value_unset_or_nil(x) -> {:cont, s}
            {:ok, s} -> {:cont, s}
            {:error, %{__struct__: _}} = result -> {:halt, result}
            s -> {:cont, s}
          end
        end
      )
      |> case do
        {:error, %{__exception__: true}} = result -> result
        s -> {:ok, s}
      end
    rescue
      error ->
        {:error, error}
    end
  end

  def reduce2_enum(_enum, _init_acc, fun) do
    new_error_result(m: "map/2 function invalid", v: fun)
  end
end
