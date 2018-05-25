defmodule Plymio.Funcio.Enum.Map.Collate do
  @moduledoc ~S"""
  Map and Collate Patterns for Enumerables.

  These functions map the elements of an *enum* and then collates the
  results according to one of the defined *patterns*.

  See `Plymio.Funcio` for overview and documentation terms.
  """

  use Plymio.Funcio.Attribute

  @type error :: Plymio.Funcio.error()
  @type opts :: Plymio.Funcio.opts()
  @type opzioni :: Plymio.Funcio.opzioni()

  import Plymio.Funcio.Error,
    only: [
      new_error_result: 1
    ]

  import Plymio.Fontais.Guard,
    only: [
      is_value_unset_or_nil: 1
    ]

  import Plymio.Fontais.Option,
    only: [
      opts_merge: 1,
      opzioni_merge: 1
    ]

  import Plymio.Funcio.Map.Utility,
    only: [
      reduce_map1_funs: 1
    ]

  import Plymio.Funcio.Enum.Map,
    only: [
      map_concurrent_enum: 2
    ]

  import Plymio.Funcio.Enum.Collate,
    only: [
      collate0_enum: 1,
      collate1_enum: 1,
      collate2_enum: 1
    ]

  @doc ~S"""
  `map_collate0_enum/2` take an *enum* and *map/1*, applies the
  *map/1* to each element of the *enum* and collates the results
  according to *pattern 0*.

  ## Examples

      iex> fun = fn v -> {:ok, v} end
      ...> [1,2,3] |> map_collate0_enum(fun)
      {:ok, [1,2,3]}

      iex> fun = fn
      ...>  3 -> {:error, %ArgumentError{message: "argument is 3"}}
      ...>  v -> {:ok, v}
      ...> end
      ...> {:error, error} = [1,2,3] |> map_collate0_enum(fun)
      ...> error |> Exception.message
      "argument is 3"

      iex> fun = :not_a_fun
      ...> {:error, error} = [1,2,3] |> map_collate0_enum(fun)
      ...> error |> Exception.message
      "map/1 function invalid, got: :not_a_fun"

      iex> fun = fn v -> {:ok, v} end
      ...> {:error, error} = 42 |> map_collate0_enum(fun)
      ...> error |> Exception.message
      ...> |> String.starts_with?("protocol Enumerable not implemented for 42")
      true

  """

  @since "0.1.0"

  @spec map_collate0_enum(any, any) :: {:ok, list} | {:error, error}

  def map_collate0_enum(enum, fun) do
    with {:ok, fun} <- fun |> reduce_map1_funs do
      try do
        enum
        |> Enum.reduce_while(
          [],
          fn value, values ->
            value
            |> fun.()
            |> case do
              {:error, %{__struct__: _}} = result ->
                {:halt, result}

              {:ok, value} ->
                {:cont, [value | values]}

              value ->
                {:halt, new_error_result(m: "pattern0 result invalid", v: value)}
            end
          end
        )
        |> case do
          {:error, %{__exception__: true}} = result -> result
          values -> {:ok, values |> Enum.reverse()}
        end
      rescue
        error ->
          {:error, error}
      end
    else
      {:error, %{__exception__: true}} = result -> result
    end
  end

  @doc ~S"""
  `map_concurrent_collate0_enum/2` works like `map_collate0_enum/2`
  except that the *map/1* function is applied to each element of the
  *enum* concurrently.

  ## Examples

      iex> fun = fn v -> {:ok, v} end
      ...> [1,2,3] |> map_concurrent_collate0_enum(fun)
      {:ok, [1,2,3]}

      iex> fun = fn
      ...>  3 -> {:error, %ArgumentError{message: "argument is 3"}}
      ...>  v -> {:ok, v}
      ...> end
      ...> {:error, error} = [1,2,3] |> map_concurrent_collate0_enum(fun)
      ...> error |> Exception.message
      "argument is 3"

      iex> fun = :not_a_fun
      ...> {:error, error} = [1,2,3] |> map_concurrent_collate0_enum(fun)
      ...> error |> Exception.message
      "map/1 function invalid, got: :not_a_fun"

      iex> fun = fn v -> {:ok, v} end
      ...> {:error, error} = 42 |> map_concurrent_collate0_enum(fun)
      ...> error |> Exception.message
      ...> |> String.starts_with?("protocol Enumerable not implemented for 42")
      true

  """

  @since "0.1.0"

  @spec map_concurrent_collate0_enum(any, any) :: {:ok, list} | {:error, error}

  def map_concurrent_collate0_enum(enum, fun) do
    try do
      with {:ok, results} <- enum |> map_concurrent_enum(fun),
           {:ok, _} = result <- results |> collate0_enum do
        result
      else
        {:error, %{__exception__: true}} = result -> result
      end
    rescue
      error ->
        {:error, error}
    end
  end

  @doc ~S"""
  `map_collate0_opts_enum/2` works like `map_collate0_enum/2` but
  assumes each `value` in the `{:ok, collated_values}` result is an
  *opts* and calls `Plymio.Fontais.Option.opts_merge/1` with
  `collated_values` returning, on success, `{:ok, opts}`.

  ## Examples

      iex> fun = fn v -> {:ok, v} end
      ...> [a: 1, b: 2, c: 3] |> map_collate0_opts_enum(fun)
      {:ok, [a: 1, b: 2, c: 3]}

      iex> fun = fn v -> {:ok, v} end
      ...> [[a: 1], [b: 2], [c: 3]] |> map_collate0_opts_enum(fun)
      {:ok, [a: 1, b: 2, c: 3]}

      iex> fun = fn v -> {:ok, [d: v]} end
      ...> [1,2,3] |> map_collate0_opts_enum(fun)
      {:ok, [d: 1, d: 2, d: 3]}

      iex> fun = fn
      ...>  {k,3} -> {:error, %ArgumentError{message: "argument for #{inspect k} is 3"}}
      ...>  v -> {:ok, v}
      ...> end
      ...> {:error, error} = [a: 1, b: 2, c: 3] |> map_collate0_opts_enum(fun)
      ...> error |> Exception.message
      "argument for :c is 3"

  """

  @since "0.1.0"

  @spec map_collate0_opts_enum(any, any) :: {:ok, opts} | {:error, error}

  def map_collate0_opts_enum(enum, fun) do
    with {:ok, values} <- enum |> map_collate0_enum(fun),
         {:ok, _opts} = result <- values |> opts_merge do
      result
    else
      {:error, %{__exception__: true}} = result -> result
    end
  end

  @doc ~S"""
  `map_collate0_opts_enum/2` works like `map_collate0_enum/2` but
  assumes each `value` in the `{:ok, collated_values}` result is an
  *opzioni* and calls `Plymio.Fontais.Option.opzioni_merge/1` with
  `collated_values` returning, on success, `{:ok, opzioni}`.

  ## Examples

      iex> fun = fn v -> {:ok, v} end
      ...> [a: 1, b: 2, c: 3] |> map_collate0_opzioni_enum(fun)
      {:ok, [[a: 1, b: 2, c: 3]]}

      iex> fun = fn v -> {:ok, v} end
      ...> [[a: 1], [b: 2], [c: 3]] |> map_collate0_opzioni_enum(fun)
      {:ok, [[a: 1], [b: 2], [c: 3]]}

      iex> fun = fn v -> {:ok, v} end
      ...> [[[a: 1], [b: 2]], [c: 3], [[d: 4]]] |> map_collate0_opzioni_enum(fun)
      {:ok, [[a: 1], [b: 2], [c: 3], [d: 4]]}

      iex> fun = fn v -> {:ok, [[d: v]]} end
      ...> [1,2,3] |> map_collate0_opzioni_enum(fun)
      {:ok, [[d: 1], [d: 2], [d: 3]]}

      iex> fun = fn
      ...>  [{k,3}] -> {:error, %ArgumentError{message: "argument for #{inspect k} is 3"}}
      ...>  v -> {:ok, v}
      ...> end
      ...> {:error, error} = [[[a: 1], [b: 2]], [c: 3], [[d: 4]]] |> map_collate0_opzioni_enum(fun)
      ...> error |> Exception.message
      "argument for :c is 3"

  """

  @since "0.1.0"

  @spec map_collate0_opzioni_enum(any, any) :: {:ok, opzioni} | {:error, error}

  def map_collate0_opzioni_enum(enum, fun) do
    with {:ok, values} <- enum |> map_collate0_enum(fun),
         {:ok, _opts} = result <- values |> opzioni_merge do
      result
    else
      {:error, %{__exception__: true}} = result -> result
    end
  end

  @doc ~S"""
  `map_concurrent_collate0_opts_enum/2` works like
  `map_collate0_opts_enum/2` but maps each each element of the *enum*
  concurrently.

  ## Examples

      iex> fun = fn v -> {:ok, v} end
      ...> [a: 1, b: 2, c: 3] |> map_concurrent_collate0_opts_enum(fun)
      {:ok, [a: 1, b: 2, c: 3]}

      iex> fun = fn v -> {:ok, v} end
      ...> [[a: 1], [b: 2], [c: 3]] |> map_concurrent_collate0_opts_enum(fun)
      {:ok, [a: 1, b: 2, c: 3]}

      iex> fun = fn v -> {:ok, [d: v]} end
      ...> [1,2,3] |> map_concurrent_collate0_opts_enum(fun)
      {:ok, [d: 1, d: 2, d: 3]}

      iex> fun = fn
      ...>  {k,3} -> {:error, %ArgumentError{message: "argument for #{inspect k} is 3"}}
      ...>  v -> {:ok, v}
      ...> end
      ...> {:error, error} = [a: 1, b: 2, c: 3] |> map_concurrent_collate0_opts_enum(fun)
      ...> error |> Exception.message
      "argument for :c is 3"

  """

  @since "0.1.0"

  @spec map_concurrent_collate0_opts_enum(any, any) :: {:ok, opts} | {:error, error}

  def map_concurrent_collate0_opts_enum(enum, fun) do
    with {:ok, values} <- enum |> map_concurrent_collate0_enum(fun),
         {:ok, _opts} = result <- values |> opts_merge do
      result
    else
      {:error, %{__exception__: true}} = result -> result
    end
  end

  @doc ~S"""
  `map_concurrent_collate0_opzioni_enum/2` works like
  `map_collate0_opzioni_enum/2` but maps each element of the *enum*
  concurrently.

  ## Examples

      iex> fun = fn v -> {:ok, v} end
      ...> [a: 1, b: 2, c: 3] |> map_concurrent_collate0_opzioni_enum(fun)
      {:ok, [[a: 1, b: 2, c: 3]]}

      iex> fun = fn v -> {:ok, v} end
      ...> [[a: 1], [b: 2], [c: 3]] |> map_concurrent_collate0_opzioni_enum(fun)
      {:ok, [[a: 1], [b: 2], [c: 3]]}

      iex> fun = fn v -> {:ok, v} end
      ...> [[[a: 1], [b: 2]], [c: 3], [[d: 4]]] |> map_concurrent_collate0_opzioni_enum(fun)
      {:ok, [[a: 1], [b: 2], [c: 3], [d: 4]]}

      iex> fun = fn v -> {:ok, [[d: v]]} end
      ...> [1,2,3] |> map_concurrent_collate0_opzioni_enum(fun)
      {:ok, [[d: 1], [d: 2], [d: 3]]}

      iex> fun = fn
      ...>  [{k,3}] -> {:error, %ArgumentError{message: "argument for #{inspect k} is 3"}}
      ...>  v -> {:ok, v}
      ...> end
      ...> {:error, error} = [[[a: 1], [b: 2]], [c: 3], [[d: 4]]] |> map_concurrent_collate0_opzioni_enum(fun)
      ...> error |> Exception.message
      "argument for :c is 3"

  """

  @since "0.1.0"

  @spec map_concurrent_collate0_opzioni_enum(any, any) :: {:ok, opzioni} | {:error, error}

  def map_concurrent_collate0_opzioni_enum(enum, fun) do
    with {:ok, values} <- enum |> map_collate0_enum(fun),
         {:ok, _opts} = result <- values |> opzioni_merge do
      result
    else
      {:error, %{__exception__: true}} = result -> result
    end
  end

  @doc ~S"""
  `map_collate1_enum/2` take an *enum* and *map/1*, applies the
  *map/1* to each element of the *enum* and collates the results
  according to *pattern 1*.

  ## Examples

      iex> fun = fn v -> {:ok, v} end
      ...> [1,2,3] |> map_collate1_enum(fun)
      {:ok, [1,2,3]}

      iex> fun = fn
      ...>  3 -> 3
      ...>  v -> {:ok, v}
      ...> end
      ...> [1,2,3] |> map_collate1_enum(fun)
      {:ok, [1,2,3]}

      iex> fun = fn
      ...>  3 -> {:error, %ArgumentError{message: "argument is 3"}}
      ...>  v -> {:ok, v}
      ...> end
      ...> {:error, error} = [1,2,3] |> map_collate1_enum(fun)
      ...> error |> Exception.message
      "argument is 3"

      iex> fun = :not_a_fun
      ...> {:error, error} = [1,2,3] |> map_collate1_enum(fun)
      ...> error |> Exception.message
      "map/1 function invalid, got: :not_a_fun"

      iex> fun = fn v -> {:ok, v} end
      ...> {:error, error} = 42 |> map_collate1_enum(fun)
      ...> error |> Exception.message
      ...> |> String.starts_with?("protocol Enumerable not implemented for 42")
      true

  """

  @since "0.1.0"

  @spec map_collate1_enum(any, any) :: {:ok, list} | {:error, error}

  def map_collate1_enum(enum, fun) do
    with {:ok, fun} <- fun |> reduce_map1_funs do
      try do
        enum
        |> Enum.reduce_while(
          [],
          fn value, values ->
            value
            |> fun.()
            |> case do
              {:error, %{__struct__: _}} = result -> {:halt, result}
              {:ok, value} -> {:cont, [value | values]}
              value -> {:cont, [value | values]}
            end
          end
        )
        |> case do
          {:error, %{__exception__: true}} = result -> result
          values -> {:ok, values |> Enum.reverse()}
        end
      rescue
        error ->
          {:error, error}
      end
    else
      {:error, %{__exception__: true}} = result -> result
    end
  end

  @doc ~S"""
  `map_concurrent_collate1_enum/2` works like `map_collate1_enum/2`
  but maps each element of the *enum* concurrently.

  ## Examples

      iex> fun = fn v -> {:ok, v} end
      ...> [1,2,3] |> map_concurrent_collate1_enum(fun)
      {:ok, [1,2,3]}

      iex> fun = fn
      ...>  3 -> 3
      ...>  v -> {:ok, v}
      ...> end
      ...> [1,2,3] |> map_concurrent_collate1_enum(fun)
      {:ok, [1,2,3]}

      iex> fun = fn
      ...>  3 -> {:error, %ArgumentError{message: "argument is 3"}}
      ...>  v -> {:ok, v}
      ...> end
      ...> {:error, error} = [1,2,3] |> map_concurrent_collate1_enum(fun)
      ...> error |> Exception.message
      "argument is 3"

      iex> fun = :not_a_fun
      ...> {:error, error} = [1,2,3] |> map_concurrent_collate1_enum(fun)
      ...> error |> Exception.message
      "map/1 function invalid, got: :not_a_fun"

      iex> fun = fn v -> {:ok, v} end
      ...> {:error, error} = 42 |> map_concurrent_collate1_enum(fun)
      ...> error |> Exception.message
      ...> |> String.starts_with?("protocol Enumerable not implemented for 42")
      true

  """

  @since "0.1.0"

  @spec map_concurrent_collate1_enum(any, any) :: {:ok, list} | {:error, error}

  def map_concurrent_collate1_enum(enum, fun) do
    try do
      with {:ok, results} <- enum |> map_concurrent_enum(fun),
           {:ok, _} = result <- results |> collate1_enum do
        result
      else
        {:error, %{__exception__: true}} = result -> result
      end
    rescue
      error ->
        {:error, error}
    end
  end

  @doc ~S"""
  `map_collate2_enum/2` take an *enum* and *map/1*, applies the
  *map/1* to each element of the *enum* and collates the results
  according to *pattern 2* but dropping results that are either `nil` or [*the unset value*](https://hexdocs.pm/plymio_fontais/Plymio.Fontais.html#module-the-unset-value).

  ## Examples

      iex> fun = fn v -> {:ok, v} end
      ...> [1,2,3] |> map_collate2_enum(fun)
      {:ok, [1,2,3]}

      iex> fun = fn
      ...>  3 -> {:error, %ArgumentError{message: "argument is 3"}}
      ...>  v -> {:ok, v}
      ...> end
      ...> {:error, error} = [1,2,3] |> map_collate2_enum(fun)
      ...> error |> Exception.message
      "argument is 3"

      iex> fun = fn
      ...>  1 -> nil
      ...>  3 -> nil
      ...>  5 -> Plymio.Fontais.Guard.the_unset_value()
      ...>  v -> {:ok, v}
      ...> end
      ...> [1,2,3,4,5] |> map_collate2_enum(fun)
      {:ok, [2,4]}

      iex> fun1 = fn
      ...>  1 -> nil
      ...>  3 -> nil
      ...>  5 -> Plymio.Fontais.Guard.the_unset_value()
      ...>  v -> {:ok, v}
      ...> end
      ...> fun2 = fn
      ...>   v when Plymio.Fontais.Guard.is_value_unset_or_nil(v) -> 42
      ...>   {:ok, v} -> {:ok, v * v * v}
      ...> end
      ...> [1,2,3,4,5] |> map_collate2_enum([fun1, fun2])
      {:ok, [42,8,42,64,42]}

      iex> fun = :not_a_fun
      ...> {:error, error} = [1,2,3] |> map_collate2_enum(fun)
      ...> error |> Exception.message
      "map/1 function invalid, got: :not_a_fun"

      iex> fun = fn v -> {:ok, v} end
      ...> {:error, error} = 42 |> map_collate2_enum(fun)
      ...> error |> Exception.message
      ...> |> String.starts_with?("protocol Enumerable not implemented for 42")
      true

  """

  @since "0.1.0"

  @spec map_collate2_enum(any, any) :: {:ok, list} | {:error, error}

  def map_collate2_enum(enum, fun) do
    with {:ok, fun} <- fun |> reduce_map1_funs do
      try do
        enum
        |> Enum.reduce_while(
          [],
          fn value, values ->
            value
            |> fun.()
            |> case do
              x when is_value_unset_or_nil(x) -> {:cont, values}
              {:error, %{__struct__: _}} = result -> {:halt, result}
              {:ok, value} -> {:cont, [value | values]}
              value -> {:cont, [value | values]}
            end
          end
        )
        |> case do
          {:error, %{__exception__: true}} = result -> result
          values -> {:ok, values |> Enum.reverse()}
        end
      rescue
        error ->
          {:error, error}
      end
    else
      {:error, %{__exception__: true}} = result -> result
    end
  end

  @doc ~S"""
  `map_concurrent_collate2_enum/2` works like `map_collate2_enum/2`
  but maps each element of the *enum* concurrently.

  ## Examples

      iex> fun = fn v -> {:ok, v} end
      ...> [1,2,3] |> map_concurrent_collate2_enum(fun)
      {:ok, [1,2,3]}

      iex> fun = fn
      ...>  3 -> {:error, %ArgumentError{message: "argument is 3"}}
      ...>  v -> {:ok, v}
      ...> end
      ...> {:error, error} = [1,2,3] |> map_concurrent_collate2_enum(fun)
      ...> error |> Exception.message
      "argument is 3"

      iex> fun = fn
      ...>  1 -> nil
      ...>  3 -> nil
      ...>  5 -> Plymio.Fontais.Guard.the_unset_value()
      ...>  v -> {:ok, v}
      ...> end
      ...> [1,2,3,4,5] |> map_concurrent_collate2_enum(fun)
      {:ok, [2,4]}

      iex> fun1 = fn
      ...>  1 -> nil
      ...>  3 -> nil
      ...>  5 -> Plymio.Fontais.Guard.the_unset_value()
      ...>  v -> {:ok, v}
      ...> end
      ...> fun2 = fn
      ...>   v when Plymio.Fontais.Guard.is_value_unset_or_nil(v) -> 42
      ...>   {:ok, v} -> {:ok, v * v * v}
      ...> end
      ...> [1,2,3,4,5] |> map_concurrent_collate2_enum([fun1, fun2])
      {:ok, [42,8,42,64,42]}

      iex> fun = :not_a_fun
      ...> {:error, error} = [1,2,3] |> map_concurrent_collate2_enum(fun)
      ...> error |> Exception.message
      "map/1 function invalid, got: :not_a_fun"

      iex> fun = fn v -> {:ok, v} end
      ...> {:error, error} = 42 |> map_concurrent_collate2_enum(fun)
      ...> error |> Exception.message
      ...> |> String.starts_with?("protocol Enumerable not implemented for 42")
      true

  """

  @since "0.1.0"

  @spec map_concurrent_collate2_enum(any, any) :: {:ok, list} | {:error, error}

  def map_concurrent_collate2_enum(enum, fun) do
    try do
      with {:ok, results} <- enum |> map_concurrent_enum(fun),
           {:ok, _} = result <- results |> collate2_enum do
        result
      else
        {:error, %{__exception__: true}} = result -> result
      end
    rescue
      error ->
        {:error, error}
    end
  end
end
