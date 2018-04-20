defmodule Plymio.Funcio.Enum.ValueAt do
  @moduledoc ~S"""
  Functions for Specific Values in an Enum.

  See `Plymio.Funcio` for overview and other documentation terms.

  ## Documentation Terms

  In the documentation below these terms, usually in *italics*, are used to mean the same thing.

  ### *index*, *indices* and *index range*

  See `Plymio.Funcio.Index`
  """

  import Plymio.Fontais.Result,
    only: [
      normalise1_result: 1
    ]

  import Plymio.Funcio.Map.Utility,
    only: [
      reduce_map1_funs: 1
    ]

  import Plymio.Funcio.Index,
    only: [
      normalise_index_range: 1
    ]

  import Plymio.Funcio.Enum.Index,
    only: [
      create_predicate_index_range_enum: 2,
      normalise_index_range_enum: 2,
      validate_index_enum: 2
    ]

  import Plymio.Funcio.Enum.Utility,
    only: [
      enum_reify: 1
    ]

  @type error :: Plymio.Funcio.error()
  @type index :: Plymio.Funcio.index()
  @type indices :: Plymio.Funcio.indices()

  @doc ~S"""
  `map_value_at_enum/3` takes an *enum*, an *index range* and a
  *map/1*.

  For each *index* in the *index range*, it calls the *map/1* with the
  current value and then splices the "listified" new value.

  The *map/1* must return `{:ok, any}`, `{:error, error}` or `value`
  (i.e. a *pattern1* result - See `Plymio.Funcio`)

  If any mapped element returns `{:error, error}` the mapping is halted and the `{:error, error}` returned.

  ## Examples

      iex> [1,2,3] |> map_value_at_enum(2, fn v -> v * v end)
      {:ok, [1,2,9]}

      iex> {:error, error} = [1,2,3] |> map_value_at_enum(0,
      ...>     fn v -> {:error, %ArgumentError{message: "value is #{inspect v}"}} end)
      ...> error |> Exception.message
      "value is 1"

      iex> [1,2,3] |> map_value_at_enum(0 .. 2, fn v -> {:ok, v * v} end)
      {:ok, [1,4,9]}

      iex> [1,2,3] |> map_value_at_enum(0 .. 2,
      ...>   [fn v -> v + 1 end, fn v -> v * v end, fn v -> v - 1 end])
      {:ok, [3,8,15]}

      iex> [1,2,3] |> map_value_at_enum([0, -1], fn v -> [:a,v] end)
      {:ok, [:a, 1, 2, :a, 3]}

      iex> [] |> map_value_at_enum(0, fn v -> v end)
      {:ok, []}

      iex> [1,2,3] |> map_value_at_enum(nil, fn _ -> :a end)
      {:ok, [:a, :a, :a]}

      iex> {:error, error} = 42 |> map_value_at_enum(0, fn v -> v end)
      ...> error |> Exception.message
      ...> |> String.starts_with?("protocol Enumerable not implemented for 42")
      true

      iex> {:error, error} = [1,2,3] |> map_value_at_enum(:not_an_index, fn v -> v end)
      ...> error |> Exception.message
      "index range invalid, got: :not_an_index"

  """

  @since "0.1.0"

  @spec map_value_at_enum(any, any, any) :: {:ok, list} | {:error, error}

  def map_value_at_enum(enum, index_range, fun_map)

  def map_value_at_enum([], _index, _fun_map) do
    {:ok, []}
  end

  def map_value_at_enum(state, index_range, fun_map) do
    with {:ok, state} <- state |> enum_reify,
         {:ok, fun_map} <- [fun_map, &normalise1_result/1] |> reduce_map1_funs,
         {:ok, fun_pred} <- state |> create_predicate_index_range_enum(index_range) do
      state
      |> Stream.with_index()
      |> Enum.reduce_while([], fn {value, index}, state ->
        {value, index}
        |> fun_pred.()
        |> case do
          x when x in [nil, false] ->
            {:cont, state ++ List.wrap(value)}

          x when x in [true] ->
            with {:ok, new_value} <- value |> fun_map.() do
              {:cont, state ++ List.wrap(new_value)}
            else
              {:error, %{__struct__: _}} = result -> {:halt, result}
            end
        end
      end)
      |> case do
        {:error, %{__exception__: true}} = result -> result
        state when is_list(state) -> {:ok, state}
      end
    else
      {:error, %{__exception__: true}} = result -> result
    end
  end

  @doc ~S"""
  `map_with_index_value_at_enum/3` takes an *enum*, an *index range* and a *map/1*.

  For each *index* in the *index range*, it calls the *map/1* with the
  current `{value, index}` 2tuple and then splices the "listified" new
  value.

  The *map/1* must return `{:ok, any}`, `{:error, error}` or `value`
  (i.e. a *pattern1* result - See `Plymio.Funcio`)

  If any mapped element returns `{:error, error}` the mapping is
  halted and the `{:error, error}` returned.

  ## Examples

      iex> [1,2,3] |> map_with_index_value_at_enum(2, fn {v,_i} -> v * v end)
      {:ok, [1,2,9]}

      iex> {:error, error} = [1,2,3] |> map_with_index_value_at_enum(0,
      ...>     fn {v,_i} -> {:error, %ArgumentError{message: "value is #{inspect v}"}} end)
      ...> error |> Exception.message
      "value is 1"

      iex> [1,2,3] |> map_with_index_value_at_enum(0 .. 2, fn {v,i} -> {:ok, v + i} end)
      {:ok, [1,3,5]}

      iex> [1,2,3] |> map_with_index_value_at_enum(0 .. 2,
      ...>   [fn {v,i} -> v + i end, fn v -> v * v end, fn v -> v - 1 end])
      {:ok, [0,8,24]}

      iex> [1,2,3] |> map_with_index_value_at_enum([0, -1], fn {v,_i} -> [:a,v] end)
      {:ok, [:a, 1, 2, :a, 3]}

      iex> [] |> map_with_index_value_at_enum(0, fn v -> v end)
      {:ok, []}

      iex> [1,2,3] |> map_with_index_value_at_enum(nil, fn _ -> :a end)
      {:ok, [:a, :a, :a]}

      iex> {:error, error} = 42 |> map_with_index_value_at_enum(0, fn v -> v end)
      ...> error |> Exception.message
      ...> |> String.starts_with?("protocol Enumerable not implemented for 42")
      true

      iex> {:error, error} = [1,2,3] |> map_with_index_value_at_enum(:not_an_index, fn v -> v end)
      ...> error |> Exception.message
      "index range invalid, got: :not_an_index"

      iex> {:error, error} = [1,2,3] |> map_with_index_value_at_enum(0, :not_a_fun)
      ...> error |> Exception.message
      "map/1 function invalid, got: :not_a_fun"

  """

  @since "0.1.0"

  @spec map_with_index_value_at_enum(any, any, any) :: {:ok, list} | {:error, error}

  def map_with_index_value_at_enum(derivable_list, index_range, fun_map)

  def map_with_index_value_at_enum([], _index, _fun_map) do
    {:ok, []}
  end

  def map_with_index_value_at_enum(state, index_range, fun_map) do
    with {:ok, state} <- state |> enum_reify,
         {:ok, fun_map} <- [fun_map, &normalise1_result/1] |> reduce_map1_funs,
         {:ok, fun_pred} <- state |> create_predicate_index_range_enum(index_range),
         true <- true do
      state
      |> Stream.with_index()
      |> Enum.reduce_while([], fn {value, index}, state ->
        {value, index}
        |> fun_pred.()
        |> case do
          x when x in [nil, false] ->
            {:cont, state ++ List.wrap(value)}

          x when x in [true] ->
            with {:ok, new_value} <- {value, index} |> fun_map.() do
              {:cont, state ++ List.wrap(new_value)}
            else
              {:error, %{__struct__: _}} = result -> {:halt, result}
            end
        end
      end)
      |> case do
        {:error, %{__exception__: true}} = result -> result
        state when is_list(state) -> {:ok, state}
      end
    else
      {:error, %{__exception__: true}} = result -> result
    end
  end

  @doc ~S"""
  `insert_value_at_enum/3` takes an *enum*, and *index range* and a value or list of values.

  It splices the "listified" (new) values at each index in the *index range*.

  If the *index range* is `:append`, the "listified" value is appended to the derived list.

  ## Examples

      iex> [1,2,3] |> insert_value_at_enum(0, :a)
      {:ok, [:a, 1, 2, 3]}

      iex> [1,2,3] |> insert_value_at_enum(nil, :a)
      {:ok, [:a, 1, :a, 2, :a, 3]}

      iex> [1,2,3] |> insert_value_at_enum(:append, [:a, :b, :c])
      {:ok, [1, 2, 3, :a, :b, :c]}

      iex> [1,2,3] |> insert_value_at_enum(0, [:a, :b, :c])
      {:ok, [:a, :b, :c, 1, 2, 3]}

      iex> [1,2,3] |> insert_value_at_enum(0 .. 2, :a)
      {:ok, [:a, 1, :a, 2, :a, 3]}

      iex> [1,2,3] |> insert_value_at_enum([0, -1], :a)
      {:ok, [:a, 1, 2, :a, 3]}

      iex> [1,2,3] |> insert_value_at_enum([0, -1], [:a,:b,:c])
      {:ok, [:a, :b, :c, 1, 2, :a, :b, :c, 3]}

      iex> [] |> insert_value_at_enum(0, :a)
      {:ok, [:a]}

      iex> %{a: 1, b: 2, c: 3} |> insert_value_at_enum(1, :x)
      {:ok, [{:a, 1}, :x, {:b, 2}, {:c, 3}]}

      iex> %{a: 1, b: 2, c: 3} |> insert_value_at_enum(1, [x: 10, y: 11, z: 12])
      {:ok, [a: 1, x: 10, y: 11, z: 12, b: 2, c: 3]}

      iex> [] |> insert_value_at_enum(-1, :a)
      {:ok, [:a]}

      iex> [1,:b,3] |> insert_value_at_enum(-1, :d)
      {:ok, [1,:b,:d,3]}

      iex> {:error, error} = 42 |> insert_value_at_enum(0, :a)
      ...> error |> Exception.message
      ...> |> String.starts_with?("protocol Enumerable not implemented for 42")
      true

      iex> {:error, error} = [1,2,3] |> insert_value_at_enum(:not_an_index, :a)
      ...> error |> Exception.message
      "index range invalid, got: :not_an_index"

  """

  @since "0.1.0"

  @spec insert_value_at_enum(any, any, any) :: {:ok, list} | {:error, error}

  def insert_value_at_enum(derivable_list, index_range, value)

  def insert_value_at_enum([], _index_range, value) do
    {:ok, value |> List.wrap()}
  end

  def insert_value_at_enum(state, :append, value) when is_list(state) do
    with {:ok, state} <- state |> enum_reify do
      {:ok, state ++ List.wrap(value)}
    else
      {:error, %{__exception__: true}} = result -> result
    end
  end

  def insert_value_at_enum(state, index_range, value) do
    entries =
      value
      |> case do
        x when is_list(x) -> x
        x -> [x]
      end

    with {:ok, state} <- state |> enum_reify,
         {:ok, fun_pred} when is_function(fun_pred, 1) <-
           state
           |> create_predicate_index_range_enum(index_range),
         true <- true do
      state
      |> Stream.with_index()
      |> Enum.reduce_while([], fn {value, index}, state ->
        {value, index}
        |> fun_pred.()
        |> case do
          x when x in [nil, false] ->
            {:cont, state ++ List.wrap(value)}

          x when x in [true] ->
            {:cont, state ++ entries ++ [value]}
        end
      end)
      |> case do
        {:error, %{__exception__: true}} = result -> result
        state when is_list(state) -> {:ok, state}
      end
    else
      {:error, %{__exception__: true}} = result -> result
    end
  end

  @doc ~S"""
  `delete_value_at_enum/3` takes an *enum*, and *index range*
  and deletes the elements in the *index range*.

  Note: If the *index range* is `nil`, the derived list is emptied returning `{:ok, []}`.

  ## Examples

      iex> [1,2,3] |> delete_value_at_enum(0)
      {:ok, [2,3]}

      iex> [1,2,3] |> delete_value_at_enum(0 .. 2)
      {:ok, []}

      iex> [1,2,3] |> delete_value_at_enum(nil)
      {:ok, []}

      iex> [1,2,3] |> delete_value_at_enum([0, -1])
      {:ok, [2]}

      iex> [] |> delete_value_at_enum(0)
      {:ok, []}

      iex> %{a: 1, b: 2, c: 3} |> delete_value_at_enum(1)
      {:ok, [a: 1, c: 3]}

      iex> {:error, error} = 42 |> delete_value_at_enum(0)
      ...> error |> Exception.message
      ...> |> String.starts_with?("protocol Enumerable not implemented for 42")
      true

      iex> {:error, error} = [1,2,3] |> delete_value_at_enum(:not_an_index)
      ...> error |> Exception.message
      "index range invalid, got: :not_an_index"

  """

  @since "0.1.0"

  @spec delete_value_at_enum(any, any) :: {:ok, list} | {:error, error}

  def delete_value_at_enum(derivable_list, index_range)

  def delete_value_at_enum([], _index) do
    {:ok, []}
  end

  def delete_value_at_enum(state, nil) when is_list(state) do
    {:ok, []}
  end

  def delete_value_at_enum(state, index_range) do
    with {:ok, state} <- state |> enum_reify,
         {:ok, fun_pred} <- state |> create_predicate_index_range_enum(index_range),
         true <- true do
      state
      |> Stream.with_index()
      |> Enum.reduce_while([], fn {value, index}, state ->
        {value, index}
        |> fun_pred.()
        |> case do
          # keep the value
          x when x in [nil, false] ->
            {:cont, state ++ List.wrap(value)}

          # drop the value
          x when x in [true] ->
            {:cont, state}
        end
      end)
      |> case do
        {:error, %{__exception__: true}} = result -> result
        state when is_list(state) -> {:ok, state}
      end
    else
      {:error, %{__exception__: true}} = result -> result
    end
  end

  @doc ~S"""
  `replace_value_at_enum/3` takes an *enum*, an *index range* and a new value.

  The new value is "listified" by calling `List.wrap/1`.

  For each *index* in the  *index range*,  it deletes the current value and
  then splices the "listified" new value.

  ## Examples

      iex> [1,2,3] |> replace_value_at_enum(0, :a)
      {:ok, [:a,2,3]}

      iex> [1,2,3] |> replace_value_at_enum(0 .. 2, :a)
      {:ok, [:a, :a, :a]}

      iex> [1,2,3] |> replace_value_at_enum([0, -1], :a)
      {:ok, [:a, 2, :a]}

      iex> [] |> replace_value_at_enum(0, :a)
      {:ok, []}

      iex> [1,2,3] |> replace_value_at_enum(nil, :a)
      {:ok, [:a, :a, :a]}

      iex> [1,2,3] |> replace_value_at_enum(nil, [:a, :b, :c])
      {:ok, [:a, :b, :c, :a, :b, :c, :a, :b, :c]}

      iex> %{a: 1, b: 2, c: 3} |> replace_value_at_enum(1, :x)
      {:ok, [{:a, 1}, :x, {:c, 3}]}

      iex> %{a: 1, b: 2, c: 3} |> replace_value_at_enum(1, [x: 10, y: 11, z: 12])
      {:ok, [a: 1, x: 10, y: 11, z: 12, c: 3]}

      iex> [1,:b,3] |> replace_value_at_enum(-1, :d)
      {:ok, [1,:b,:d]}

      iex> {:error, error} = 42 |> replace_value_at_enum(0, :a)
      ...> error |> Exception.message
      ...> |> String.starts_with?("protocol Enumerable not implemented for 42")
      true

      iex> {:error, error} = [1,2,3] |> replace_value_at_enum(:not_an_index, :a)
      ...> error |> Exception.message
      "index range invalid, got: :not_an_index"

  """

  @since "0.1.0"

  @spec replace_value_at_enum(any, any, any) :: {:ok, list} | {:error, error}

  def replace_value_at_enum(derivable_list, index_range, value)

  def replace_value_at_enum([], _index, _value) do
    {:ok, []}
  end

  def replace_value_at_enum(state, index_range, value) do
    entries =
      value
      |> case do
        x when is_list(x) -> x
        x -> [x]
      end

    with {:ok, state} <- state |> enum_reify,
         {:ok, fun_pred} <- state |> create_predicate_index_range_enum(index_range),
         true <- true do
      state
      |> Stream.with_index()
      |> Enum.reduce_while([], fn {value, index}, state ->
        {value, index}
        |> fun_pred.()
        |> case do
          x when x in [nil, false] ->
            {:cont, state ++ List.wrap(value)}

          x when x in [true] ->
            {:cont, state ++ entries}
        end
      end)
      |> case do
        {:error, %{__exception__: true}} = result -> result
        state when is_list(state) -> {:ok, state}
      end
    else
      {:error, %{__exception__: true}} = result -> result
    end
  end

  @doc ~S"""
  `fetch_value_at_enum/2` takes a *derivable list* and an *index range*, and
  returns the `value` at each index as `{:ok, values}`.

  An unknown or invalid *index* will cause an error.

  Values are returned in the same order as the *index range*. Indices may be
  repeated.

  If the *index range* is `nil`, all values will be returned.

  ## Examples

      iex> [1,2,3] |> fetch_value_at_enum
      {:ok, [1, 2, 3]}

      iex> [1,2,3] |> fetch_value_at_enum(0)
      {:ok, [1]}

      iex> {:error, error} = [] |> fetch_value_at_enum(0)
      ...> error |> Exception.message
      "index invalid, got: 0"

      iex> [1,2,3] |> fetch_value_at_enum(1 .. 2)
      {:ok, [2, 3]}

      iex> [1,2,3] |> fetch_value_at_enum([2, 2, 2])
      {:ok, [3, 3, 3]}

      iex> [1,2,3] |> fetch_value_at_enum([1 .. 2, 0, 0 .. 2])
      {:ok, [2, 3, 1, 1, 2, 3]}

      iex> {:error, error} = [1,2,3] |> fetch_value_at_enum(99)
      ...> error |> Exception.message
      "index invalid, got: 99"

      iex> {:error, error} = [1,2,3] |> fetch_value_at_enum([99, 123])
      ...> error |> Exception.message
      "indices invalid, got: [99, 123]"

      iex> {:error, error} = [1,2,3] |> fetch_value_at_enum([:not_an_index, 99])
      ...> error |> Exception.message
      "index invalid, got: :not_an_index"

  """

  @since "0.1.0"

  @spec fetch_value_at_enum(any, any) :: {:ok, list} | {:error, error}

  def fetch_value_at_enum(derivable_list, index_range \\ nil)

  def fetch_value_at_enum(state, nil) do
    {:ok, state}
  end

  def fetch_value_at_enum(state, index_range) do
    with {:ok, state} <- state |> enum_reify,
         {:ok, range_indices} <- state |> normalise_index_range_enum(index_range) do
      {:ok, range_indices |> Enum.map(fn index -> state |> Enum.at(index) end)}
    else
      {:error, %{__exception__: true}} = result -> result
    end
  end

  @doc ~S"""
  `get_value_at_enum/2` takes a *derivable list*, an *index range*, and a default value.

  For each *index* in the *index range* it checks if the *index* is in the list and gets its value if so; otherwise the default is used.

  It returns `{:ok, values}`.

  Values are returned in the same order as the *index range*. Indices may be repeated.

  If the *index range* is `nil`, all values will be returned.

  > Note there is no constraint on (size of) the *index range*; all unknown *indices* will use the default and could cause the `values` to be a large list.

  ## Examples

      iex> [1,2,3] |> get_value_at_enum
      {:ok, [1, 2, 3]}

      iex> [1,2,3] |> get_value_at_enum(0)
      {:ok, [1]}

      iex> [] |> get_value_at_enum(0, 42)
      {:ok, [42]}

      iex> [1,2,3] |> get_value_at_enum(99, 42)
      {:ok, [42]}

      iex> [1,2,3] |> get_value_at_enum([0, 3, 4, -1], 42)
      {:ok, [1, 42, 42, 3]}

      iex> [1,2,3] |> get_value_at_enum(1 .. 2)
      {:ok, [2, 3]}

      iex> [1,2,3] |> get_value_at_enum([2, 2, 2])
      {:ok, [3, 3, 3]}

      iex> [1,2,3] |> get_value_at_enum([1 .. 2, 0, 0 .. 2], 42)
      {:ok, [2, 3, 1, 1, 2, 3]}

      iex> {:error, error} = [1,2,3] |> get_value_at_enum([:not_an_index, 99])
      ...> error |> Exception.message
      "index invalid, got: :not_an_index"

  """
  @since "0.1.0"

  @spec get_value_at_enum(any, any, any) :: {:ok, list} | {:error, error}

  def get_value_at_enum(derivable_list, index_range \\ nil, default \\ nil)

  def get_value_at_enum(state, nil, _default) do
    {:ok, state}
  end

  def get_value_at_enum(state, index_range, default) do
    with {:ok, state} <- state |> enum_reify,
         {:ok, range_indices} <- index_range |> normalise_index_range do
      state_map = state |> Stream.with_index() |> Map.new(fn {v, i} -> {i, v} end)

      range_indices
      |> Enum.reduce([], fn index, values ->
        state
        |> validate_index_enum(index)
        |> case do
          {:ok, index} ->
            [Map.get(state_map, index) | values]

          {:error, %{__struct__: _}} ->
            [default | values]
        end
      end)
      |> case do
        indices ->
          {:ok, indices |> Enum.reverse()}
      end
    else
      {:error, %{__exception__: true}} = result -> result
    end
  end
end
