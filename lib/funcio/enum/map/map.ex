defmodule Plymio.Funcio.Enum.Map do
  @moduledoc ~S"""
  Map Functions for an Enumerable.

  See `Plymio.Funcio` for overview and documentation terms.

  > The concurrent functions currently produce a `List` rather than a
    `Stream`. But this could change in the future. The examples below assumes a `Stream` was returned.
  """

  use Plymio.Funcio.Attribute

  @type opts :: Plymio.Funcio.opts()
  @type error :: Plymio.Funcio.error()
  @type result :: Plymio.Funcio.result()
  @type fun1_map :: Plymio.Funcio.fun1_map()

  import Plymio.Fontais.Option,
    only: [
      opts_normalise: 1,
      opts_validate: 1,
      opts_get: 3
    ]

  import Plymio.Funcio.Enum.Collate,
    only: [
      collate0_enum: 1
    ]

  import Plymio.Funcio.Map.Utility,
    only: [
      reduce_or_passthru_map1_funs: 1,
      reduce_map1_funs: 1
    ]

  @doc ~S"""
  `map_enum/3` takes an *enum* and a *map/1*, reduces the
  *map/1* to a single, composite function and applied the composite to each value in
  the *enum* returning `{:ok, values}` where `values` *may* be a `Stream`.

  ## Examples

      iex> enum = 0 .. 4
      ...> fun_map = fn v -> v * v end
      ...> {:ok, values} = enum
      ...> |> map_enum(fun_map)
      ...> values |> Enum.to_list
      [0, 1, 4, 9, 16]

      iex> enum = 0 .. 4
      ...> fun_map1 = fn v -> v + 1 end
      ...> fun_map2 = fn v -> v * v end
      ...> fun_map3 = fn v -> v - 1 end
      ...> {:ok, values} = enum
      ...> |> map_enum([fun_map1, fun_map2, fun_map3])
      ...> values |> Enum.to_list
      [0, 3, 8, 15, 24]

      iex> enum = 0 .. 99 |> Stream.map(&(&1))
      ...> fun_map = fn v -> v end
      ...> {:ok, values} = enum
      ...> |> map_enum(fun_map)
      ...> values |> Enum.reduce(0, fn v,s -> s + v end)
      4950

      iex> enum = :not_an_enum
      ...> fun_map = fn v -> v * v end
      ...> {:ok, stream} = enum |> map_enum(fun_map)
      ...> try do
      ...>   stream |> Enum.to_list
      ...> rescue
      ...>   error -> error
      ...> end
      ...> |> Exception.message
      ...> |> String.starts_with?("protocol Enumerable not implemented for :not_an_enum")
      true

  """

  @since "0.1.0"

  @spec map_enum(any, fun) :: result

  def map_enum(enum, fun)

  def map_enum(enum, fun) do
    with {:ok, fun_map} <- fun |> reduce_or_passthru_map1_funs do
      try do
        {:ok, enum |> Stream.map(fun_map)}
      rescue
        error ->
          {:error, error}
      end
    else
      {:error, %{__exception__: true}} = result -> result
    end
  end

  @doc ~S"""
  `map_concurrent_enum/3` takes an *enum* and a *map/1*, reduces the
  *map/1* to a single, composite function and applied the composite to each value in
  the *enum* in its own, separate task using using
  `Task.Supervisor.async_stream_nolink/4`.

  It returns `{:ok, values}` where the `values` *may* be a `Stream`.

  ## Examples

      iex> enum = 0 .. 4
      ...> fun_map = fn v -> v * v end
      ...> {:ok, values} = enum
      ...> |> map_concurrent_enum(fun_map)
      ...> values |> Enum.to_list
      [0, 1, 4, 9, 16]

      iex> enum = 0 .. 4
      ...> fun_map1 = fn v -> v + 1 end
      ...> fun_map2 = fn v -> v * v end
      ...> fun_map3 = fn v -> v - 1 end
      ...> {:ok, values} = enum
      ...> |> map_concurrent_enum([fun_map1, fun_map2, fun_map3])
      ...> values |> Enum.to_list
      [0, 3, 8, 15, 24]

      iex> enum = 0 .. 99
      ...> fun_map = fn v -> v end
      ...> {:ok, values} = enum |> map_concurrent_enum(fun_map)
      ...> values |> Enum.reduce(0, fn v, s -> s + v end)
      4950

      iex> enum = :not_an_enum
      ...> fun_map = fn v -> v * v end
      ...> {:error, error} = enum |> map_concurrent_enum(fun_map)
      ...> error |> Exception.message
      ...> |> String.starts_with?("protocol Enumerable not implemented for :not_an_enum")
      true

  """

  @since "0.1.0"

  @spec map_concurrent_enum(any, fun, opts) :: result

  def map_concurrent_enum(enum, fun, opts \\ [])

  def map_concurrent_enum(enum, fun, opts) do
    with {:ok, opts} <- opts |> opts_normalise,
         {:ok, fun_map} <- fun |> reduce_or_passthru_map1_funs,
         {:ok, task_sup} <- opts |> opts_resolve_task_sup_pid,
         {:ok, async_stream_opts} <- opts |> opts_resolve_task_sup_async_stream_opts do
      try do
        task_stream =
          task_sup
          |> Task.Supervisor.async_stream_nolink(enum, fun_map, async_stream_opts)

        with {:ok, _results} = result <- task_stream |> realise_task_stream_results,
             {:ok, _} <- task_sup |> stop_task_supervisor do
          result
        else
          {:error, %{__exception__: true}} = result -> result
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
  `map_with_index_enum/2` take a *enum* and a *index map/1* and
  maps the *enum* with `Stream.with_index/1` and then `Stream.map/2` returning
  `{:ok, stream}`.

  The *index map/1* is called with `{value, index}` for each `value` in the *enum*.

  ## Examples

      iex> {:ok, stream} = [1,2,3] |> map_with_index_enum(fn {v,_i} -> v * v end)
      ...> stream |> Enum.to_list
      [1, 4, 9]

      iex> {:ok, stream} = [1,2,3] |> map_with_index_enum(fn {_v,i} -> i * i end)
      ...> stream |> Enum.to_list
      [0, 1, 4]

      iex> {:ok, stream} = [a: 1, b: 2, c: 3]
      ...> |> map_with_index_enum(fn {{_k,v},i} -> v * v * i end)
      ...> stream |> Enum.to_list
      [0, 4, 18]

      iex> {:ok, stream} = [a: 1, b: 2, c: 3]
      ...> |> map_with_index_enum([
      ...>      fn {{_k,v},i} -> {i, v * v} end,
      ...>      fn {i, v} -> i + v end,
      ...> ])
      ...> stream |> Enum.to_list
      [1, 5, 11]

      iex> enum = :not_an_enum
      ...> fun_map = fn v -> v * v end
      ...> {:ok, stream} = enum |> map_with_index_enum(fun_map)
      ...> try do
      ...>   stream |> Enum.to_list
      ...> rescue
      ...>   error -> error
      ...> end
      ...> |> Exception.message
      ...> |> String.starts_with?("protocol Enumerable not implemented for :not_an_enum")
      true

      iex> {:error, error} = [1,2,3] |> map_with_index_enum(:not_a_fun)
      ...> error |> Exception.message
      "map/1 function invalid, got: :not_a_fun"

  """

  @since "0.1.0"

  @spec map_with_index_enum(any, any) :: {:ok, list} | {:error, error}

  def map_with_index_enum(derivable_list, mapper)

  def map_with_index_enum(state, mapper) do
    with {:ok, fun} <- mapper |> reduce_map1_funs do
      try do
        {:ok, state |> Stream.with_index() |> Stream.map(fun)}
      rescue
        error ->
          {:error, error}
      end
    else
      {:error, %{__exception__: true}} = result -> result
    end
  end

  @doc ~S"""
  `map_concurrent_with_index_enum/2` take a *enum* and a *index map/1* and
  maps the *enum* with `Stream.with_index/1` and then `map_concurrent_enum/2` returning
  `{:ok, stream}`.

  The *index map/1* is called with `{value, index}` for each `value` in the *enum*.

  ## Examples

      iex> {:ok, stream} = [1,2,3] |> map_concurrent_with_index_enum(fn {v,_i} -> v * v end)
      ...> stream |> Enum.to_list
      [1, 4, 9]

      iex> {:ok, stream} = [1,2,3] |> map_concurrent_with_index_enum(fn {_v,i} -> i * i end)
      ...> stream |> Enum.to_list
      [0, 1, 4]

      iex> {:ok, stream} = [a: 1, b: 2, c: 3]
      ...> |> map_concurrent_with_index_enum(fn {{_k,v},i} -> v * v * i end)
      ...> stream |> Enum.to_list
      [0, 4, 18]

      iex> {:ok, stream} = [a: 1, b: 2, c: 3]
      ...> |> map_concurrent_with_index_enum([
      ...>      fn {{_k,v},i} -> {i, v * v} end,
      ...>      fn {i, v} -> i + v end,
      ...> ])
      ...> stream |> Enum.to_list
      [1, 5, 11]

      iex> {:error, error} = 42 |> map_concurrent_with_index_enum(&(&1))
      ...> error |> Exception.message
      ...> |> String.starts_with?("protocol Enumerable not implemented for 42")
      true

      iex> {:error, error} = [1,2,3] |> map_concurrent_with_index_enum(:not_a_fun)
      ...> error |> Exception.message
      "map/1 function invalid, got: :not_a_fun"

  """

  @since "0.1.0"

  @spec map_concurrent_with_index_enum(any, any) :: {:ok, list} | {:error, error}

  def map_concurrent_with_index_enum(enum, mapper)

  def map_concurrent_with_index_enum(state, mapper) do
    state |> Stream.with_index() |> map_concurrent_enum(mapper)
  end

  defp normalise_task_stream_result(value)

  defp normalise_task_stream_result({:ok, _} = result) do
    result
  end

  defp normalise_task_stream_result({:error, error}) do
    error |> normalise_task_stream_error_result!
  end

  defp normalise_task_stream_result({:exit, {value, _stacktrace}}) do
    value |> normalise_task_stream_error_result!
  end

  defp normalise_task_stream_results(results) do
    {:ok, results |> Stream.map(&normalise_task_stream_result/1)}
  end

  defp realise_task_stream_results(results) do
    with {:ok, stream} <- results |> normalise_task_stream_results do
      stream
      |> collate0_enum
    else
      {:error, %{__exception__: true}} = result -> result
    end
  end

  defp normalise_task_stream_error_value(value, exception) do
    cond do
      Exception.exception?(value) ->
        {:ok, value}

      true ->
        cond do
          Exception.exception?(exception) ->
            {:ok, exception}
        end
    end
  end

  defp normalise_task_stream_error_result(value, exception) do
    value
    |> normalise_task_stream_error_value(exception)
    |> case do
      {:ok, error} ->
        {:ok, {:error, error}}
    end
  end

  defp normalise_task_stream_error_result!(value, exception \\ nil) do
    value
    |> normalise_task_stream_error_result(exception)
    |> case do
      {:ok, result} ->
        result
    end
  end

  defp opts_resolve_task_sup_pid(opts)

  defp opts_resolve_task_sup_pid(opts) do
    with {:ok, opts} <- opts |> opts_validate do
      opts
      |> Keyword.has_key?(@plymio_funcio_key_task_sup_pid)
      |> case do
        true ->
          opts |> Keyword.fetch(@plymio_funcio_key_task_sup_pid)

        _ ->
          with {:ok, sup_opts} <- opts |> opts_resolve_task_sup_start_link_opts,
               {:ok, _sup_pid} = result <- sup_opts |> Task.Supervisor.start_link() do
            result
          else
            {:error, %{__exception__: true}} = result -> result
          end
      end
    else
      {:error, %{__exception__: true}} = result -> result
    end
  end

  defp opts_resolve_task_sup_start_link_opts(opts)

  defp opts_resolve_task_sup_start_link_opts(
         opts,
         defaults \\ @plymio_funcio_defaults_task_sup_start_link_opts
       ) do
    with {:ok, _sup_pid} = result <-
           opts |> opts_get(@plymio_funcio_key_task_sup_start_link_opts, defaults) do
      result
    else
      {:error, %{__exception__: true}} = result -> result
    end
  end

  defp opts_resolve_task_sup_async_stream_opts(opts)

  defp opts_resolve_task_sup_async_stream_opts(
         opts,
         defaults \\ @plymio_funcio_defaults_task_sup_async_stream_opts
       ) do
    with {:ok, _sup_pid} = result <-
           opts |> opts_get(@plymio_funcio_key_task_sup_async_stream_opts, defaults) do
      result
    else
      {:error, %{__exception__: true}} = result -> result
    end
  end

  defp stop_task_supervisor(pid)

  defp stop_task_supervisor(pid) when is_pid(pid) do
    pid
    |> Supervisor.stop()
    |> case do
      :ok -> {:ok, pid}
    end
  end
end
