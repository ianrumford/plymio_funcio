defmodule Plymio.Funcio.Enum.Select do
  @moduledoc ~S"""
  Selecting Specific Elements from an Enum.

  See `Plymio.Funcio` for overview and documentation terms.
  """

  import Plymio.Funcio.Predicate,
    only: [
      reduce_and_predicate1_funs: 1
    ]

  import Plymio.Funcio.Enum.ValueAt,
    only: [
      fetch_value_at_enum: 2,
      delete_value_at_enum: 2
    ]

  @type error :: Plymio.Funcio.error()
  @type stream :: Plymio.Funcio.stream()

  @doc ~S"""
  `filter_enum/2` takes a *enum* as its first argument.

  If the second argument is a *predicate/1*, it
  filters the *enum* (`Stream.filter/2`) returning
  `{:ok, stream}`.

  Otherwise the second argument is assumed to be a *index range* and
  `Plymio.Funcio.Enum.ValueAt.fetch_value_at_enum/2` is called.

  Note: the filtered list is
  returned in the **order of the indices** (so out of order and
  duplicates are allowed)

  ## Examples

      iex> {:ok, stream} = [1,2,3] |> filter_enum(&is_integer/1)
      ...> stream |> Enum.to_list
      [1,2,3]

      iex> {:ok, stream} = [1,2,3] |> filter_enum(0)
      ...> stream |> Enum.to_list
      [1]

      iex> {:ok, stream} = [1,2,3] |> filter_enum([-1, -2, 0, 1, 2])
      ...> stream |> Enum.to_list
      [3, 2, 1, 2, 3]

      iex> {:ok, stream} = [1,2,3] |> filter_enum(nil)
      ...> stream |> Enum.to_list
      [1, 2, 3]

      iex> {:ok, stream} = [1,:b,3] |> filter_enum(&is_integer/1)
      ...> stream |> Enum.to_list
      [1,3]

      iex> {:ok, stream} = [a: 1, b: 2, c: 3]
      ...> |> filter_enum(fn {_k,v} -> is_integer(v) end)
      ...> stream |> Enum.to_list
      [a: 1, b: 2, c: 3]

      iex> {:ok, stream} = [a: 1, b: 2, c: 3]
      ...> |> filter_enum([
      ...>      fn {_k,v} -> is_integer(v) end,
      ...>      fn {_k,v} -> v > 1 end,
      ...> ])
      ...> stream |> Enum.to_list
      [b: 2, c: 3]

      iex> {:ok, stream} = %{:a => 1, :b => 2, "c" => 3}
      ...> |> filter_enum(fn {k,_v} -> is_atom(k) end)
      ...> stream |> Enum.to_list
      [a: 1, b: 2]

      iex> {:ok, stream} = 42 |> filter_enum(&(&1))
      ...> try do
      ...>   stream |> Enum.to_list
      ...> rescue
      ...>   error -> error
      ...> end
      ...> |> Exception.message
      ...> |> String.starts_with?("protocol Enumerable not implemented for 42")
      true

      iex> {:error, error} = [1,2,3] |> filter_enum(:not_a_fun)
      ...> error |> Exception.message
      "index range invalid, got: :not_a_fun"

  """

  @since "0.1.0"

  @spec filter_enum(any, any) :: {:ok, list} | {:ok, stream} | {:error, error}

  def filter_enum(enum, filter_or_index_range)

  def filter_enum(state, filter) do
    filter
    |> reduce_and_predicate1_funs
    |> case do
      {:ok, fun} ->
        {:ok, state |> Stream.filter(fun)}

      # try an index range
      {:error, %{__struct__: _}} = _predicate_result ->
        state |> fetch_value_at_enum(filter)
    end
  end

  @doc ~S"""
  `reject_enum/2` takes a *enum* as its first argument.

  If the second argument is a *predicate/1*, it
  rejects the *enum* (`Stream.reject/2`) returning
  `{:ok, stream}`.

  Otherwise the second argument is assumed to be a *index range* and
  `Plymio.Funcio.Enum.ValueAt.delete_value_at_enum/2` is called.

  ## Examples

      iex> {:ok, stream} = [1,2,3] |> reject_enum(&is_integer/1)
      ...> stream |> Enum.to_list
      []

      iex> {:ok, stream} = [1,2,3] |> reject_enum(0)
      ...> stream |> Enum.to_list
      [2, 3]

      iex> {:ok, stream} = [1,2,3] |> reject_enum([-1, -2, 0, 1, 2])
      ...> stream |> Enum.to_list
      []

      iex> {:ok, stream} = [1,:b,3] |> reject_enum(&is_integer/1)
      ...> stream |> Enum.to_list
      [:b]

      iex> {:ok, stream} = [a: 1, b: 2, c: 3]
      ...> |> reject_enum(fn {_k,v} -> v > 2 end)
      ...> stream |> Enum.to_list
      [a: 1, b: 2]

      iex> {:ok, stream} = %{:a => 1, :b => 2, "c" => 3}
      ...> |> reject_enum(fn {k,_v} -> is_atom(k) end)
      ...> stream |> Enum.to_list
      [{"c", 3}]

      iex> {:ok, stream} = 42 |> reject_enum(&(&1))
      ...> try do
      ...>   stream |> Enum.to_list
      ...> rescue
      ...>   error -> error
      ...> end
      ...> |> Exception.message
      ...> |> String.starts_with?("protocol Enumerable not implemented for 42")
      true

      iex> {:error, error} = [1,2,3] |> reject_enum(:not_a_fun)
      ...> error |> Exception.message
      "index range invalid, got: :not_a_fun"

  """

  @since "0.1.0"

  @spec reject_enum(any, any) :: {:ok, list} | {:ok, stream} | {:error, error}

  def reject_enum(enum, filter_or_index_range)

  def reject_enum(state, filter) do
    filter
    |> reduce_and_predicate1_funs
    |> case do
      {:ok, fun} ->
        {:ok, state |> Stream.reject(fun)}

      # try an index range
      {:error, %{__struct__: _}} = _predicate_result ->
        state |> delete_value_at_enum(filter)
    end
  end

  @doc ~S"""
  `filter_with_index_enum/2` takes an *enum* and a *index tuple predicate/1*.

  It first passes the *enum* through `Stream.with_index/1` before
  calling `Stream.filter/2`.  The *index tuple predicate/1* is called
  with a 2tuple: `{value, index}` and, if the return is *truthy*, the
  2tuple is used as the result.

  On sucess, the result will be `{:ok, stream}` where `stream` is a `Stream`.

  ## Examples

      iex> {:ok, stream} = [:a,:b,:c]
      ...> |> filter_with_index_enum(fn {v,_i} -> is_atom(v) end)
      ...> stream |> Enum.to_list
      [{:a, 0}, {:b, 1}, {:c, 2}]

      iex> {:ok, stream} = [:a,:b,:c]
      ...> |> filter_with_index_enum(fn {_v,i} -> i > 0 end)
      ...> stream |> Enum.to_list
      [{:b, 1}, {:c, 2}]

      iex> {:ok, stream} = [a: 1, b: 2, c: 3]
      ...> |> filter_with_index_enum([
      ...>      fn {{_k,v}, _i} -> is_integer(v) end,
      ...>      fn {{_k,v}, _i} -> v > 1 end,
      ...>      fn {{_k,_v}, i} -> i > 1 end,
      ...> ])
      ...> stream |> Enum.to_list
      [{{:c, 3}, 2}]

      iex> {:ok, stream} = [a: 1, b: 2, c: 3]
      ...> |> filter_with_index_enum(fn {{_k,_v},i} -> i > 1 end)
      ...> stream |> Enum.to_list
      [{{:c, 3}, 2}]

      iex> {:ok, stream} = %{:a => 1, :b => 2, "c" => 3}
      ...> |> filter_with_index_enum(fn {{k,_v}, _i} -> is_atom(k) end)
      ...> stream |> Enum.to_list
      [{{:a, 1}, 0}, {{:b, 2}, 1}]

      iex> {:ok, stream} = 42 |> filter_with_index_enum(&(&1))
      ...> try do
      ...>   stream |> Enum.to_list
      ...> rescue
      ...>   error -> error
      ...> end
      ...> |> Exception.message
      ...> |> String.starts_with?("protocol Enumerable not implemented for 42")
      true

      iex> {:error, error} = [1,2,3] |> filter_with_index_enum(:not_a_fun)
      ...> error |> Exception.message
      "predicate/1 function invalid, got: :not_a_fun"

  """

  @since "0.1.0"

  @spec filter_with_index_enum(any, any) :: {:ok, list} | {:ok, stream} | {:error, error}

  def filter_with_index_enum(enum, filter)

  def filter_with_index_enum(state, filter) do
    with {:ok, fun} <- filter |> reduce_and_predicate1_funs do
      try do
        {:ok, state |> Stream.with_index() |> Stream.filter(fun)}
      rescue
        error ->
          {:error, error}
      end
    else
      {:error, %{__exception__: true}} = result -> result
    end
  end

  @doc ~S"""
  `reject_with_index_enum/2` takes an *enum* and a *index tuple predicate/1*.

  It first passes the *enum* through `Stream.with_index/1` before
  calling `Enum.reject/2`.

  The *index tuple predicate/1* is called with a 2tuple: `{value,
  index}` and, if the return is *truthy*, the 2tuple is rejected.

  On sucess, the result will be `{:ok, stream}` where `stream` is a `Stream`.

  ## Examples

      iex> {:ok, stream} = [1,2,3]
      ...> |> reject_with_index_enum(fn {v,_i} -> is_integer(v) end)
      ...> stream |> Enum.to_list
      []

      iex> {:ok, stream} = [1,:b,3]
      ...> |> reject_with_index_enum(fn {v,_i} -> is_integer(v) end)
      ...> stream |> Enum.to_list
      [{:b, 1}]

      iex> {:ok, stream} = [a: 1, b: 2, c: 3]
      ...> |> reject_with_index_enum(fn {{_k,_v}, i} -> i > 1 end)
      ...> stream |> Enum.to_list
      [{{:a, 1}, 0}, {{:b, 2}, 1}]

      iex> {:ok, stream} = %{:a => 1, :b => 2, "c" => 3}
      ...> |> reject_with_index_enum(fn {{k,_v}, _i} -> is_atom(k) end)
      ...> stream |> Enum.to_list
      [{{"c", 3}, 2}]

      iex> {:ok, stream} = 42 |> reject_with_index_enum(&(&1))
      ...> try do
      ...>   stream |> Enum.to_list
      ...> rescue
      ...>   error -> error
      ...> end
      ...> |> Exception.message
      ...> |> String.starts_with?("protocol Enumerable not implemented for 42")
      true

      iex> {:error, error} = [1,2,3] |> reject_with_index_enum(:not_a_fun)
      ...> error |> Exception.message
      "predicate/1 function invalid, got: :not_a_fun"

  """

  @since "0.1.0"

  @spec reject_with_index_enum(any, any) :: {:ok, list} | {:error, error}

  def reject_with_index_enum(enum, filter)

  def reject_with_index_enum(state, filter) do
    with {:ok, fun} <- filter |> reduce_and_predicate1_funs do
      try do
        {:ok, state |> Stream.with_index() |> Stream.reject(fun)}
      rescue
        error ->
          {:error, error}
      end
    else
      {:error, %{__exception__: true}} = result -> result
    end
  end
end
