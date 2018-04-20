defmodule Plymio.Funcio.Map.Utility do
  @moduledoc ~S"""
  Map Utility Functions.

  See `Plymio.Funcio` for overview and documentation terms.
  """

  use Plymio.Funcio.Attribute

  @type error :: Plymio.Funcio.error()
  @type fun1_map :: Plymio.Funcio.fun1_map()

  import Plymio.Funcio.Error,
    only: [
      new_error_result: 1
    ]

  import Plymio.Fontais.Utility,
    only: [
      list_wrap_flat_just: 1
    ]

  import Plymio.Funcio.Enum.Collate,
    only: [
      collate0_enum: 1
    ]

  @doc ~S"""
  `validate_map1_fun/1` validates the argument is an arity 1 function, returning `{:ok, fun}` or `{:error, error}`.

  ## Examples

      iex> fun1 = fn v -> v end
      ...> {:ok, fun2} = fun1 |> validate_map1_fun
      ...> fun2 |> is_function(1)
      true

      iex> fun1 = fn _k,v -> v end
      ...> {:error, error} = fun1 |> validate_map1_fun
      ...> error |> Exception.message |> String.starts_with?("map/1 function invalid")
      true

      iex> fun1 = 42
      ...> {:error, error} = fun1 |> validate_map1_fun
      ...> error |> Exception.message
      "map/1 function invalid, got: 42"

  """

  @since "0.1.0"

  @spec validate_map1_fun(any) :: {:ok, (any -> any)} | {:error, error}

  def validate_map1_fun(fun)

  def validate_map1_fun(fun) when is_function(fun, 1) do
    {:ok, fun}
  end

  def validate_map1_fun(fun) do
    new_error_result(m: "map/1 function invalid", v: fun)
  end

  @doc ~S"""
  `validate_map1_funs/1` validates the argument is a list of arity 1 functions, returning `{:ok, funs}` or `{:error, error}`.

  ## Examples

      iex> fun1 = fn v -> v end
      ...> {:error, error} = fun1 |> validate_map1_funs
      ...> error |> Exception.message |> String.starts_with?("map/1 functions invalid")
      true

      iex> fun1 = [fn v -> v end]
      ...> {:ok, fun2} = fun1 |> validate_map1_funs
      ...> fun2 |> Enum.all?(&(is_function(&1,1)))
      true

      iex> fun1 = [fn v -> v end, fn _k,v -> v end]
      ...> {:error, error} = fun1 |> validate_map1_funs
      ...> error |> Exception.message |> String.starts_with?("map/1 function invalid")
      true

  """

  @since "0.1.0"

  @spec validate_map1_funs(any) :: {:ok, [fun1_map]} | {:error, error}

  def validate_map1_funs(funs)

  def validate_map1_funs(funs) when is_list(funs) do
    funs
    |> Enum.map(&validate_map1_fun/1)
    |> collate0_enum
  end

  def validate_map1_funs(funs) do
    new_error_result(m: "map/1 functions invalid", v: funs)
  end

  @doc ~S"""
  `normalise_map1_funs/1` calls `Plymio.Fontais.Utility.list_wrap_flat_just/1` on the argument and then calls `validate_map1_funs/1`, returning `{:ok, funs}`.

  ## Examples

      iex> fun1 = fn v -> v end
      ...> {:ok, funs} = fun1 |> normalise_map1_funs
      ...> funs |> Enum.all?(&(is_function(&1,1)))
      true

      iex> fun1 = [fn v -> v end]
      ...> {:ok, funs} = fun1 |> normalise_map1_funs
      ...> funs |> Enum.all?(&(is_function(&1,1)))
      true

      iex> fun1 = [fn v -> v + 1 end, fn v -> v * v end, fn v -> v - 1 end]
      ...> {:ok, funs} = fun1 |> normalise_map1_funs
      ...> funs |> Enum.all?(&(is_function(&1,1)))
      true

      iex> fun1 = [fn v -> v end, fn _k,v -> v end]
      ...> {:error, error} = fun1 |> normalise_map1_funs
      ...> error |> Exception.message |> String.starts_with?("map/1 function invalid")
      true

  """

  @since "0.1.0"

  @spec normalise_map1_funs(any) :: {:ok, [fun1_map]} | {:error, error}

  def normalise_map1_funs(funs)

  def normalise_map1_funs(funs) do
    funs
    |> list_wrap_flat_just
    |> validate_map1_funs
  end

  @doc ~S"""
  `reduce_map1_funs/1` takes one or more map/1 functions, validates them, and reduces them into a single map/1 function for use with e.g. `Enum.map/2`.

  ## Examples

      iex> fun1 = fn v -> v end
      ...> {:ok, fun2} = fun1 |> reduce_map1_funs
      ...> 42 |> fun2.()
      42

      iex> fun1 = [fn v -> v + 5 end, fn v -> v - 11 end, fn v -> v * v end]
      ...> {:ok, fun2} = fun1 |> reduce_map1_funs
      ...> 42 |> fun2.()
      1296

      iex> fun1 = fn k,v -> {k,v} end
      ...> {:error, error} = fun1 |> reduce_map1_funs
      ...> error |> Exception.message |> String.starts_with?("map/1 function invalid")
      true

      iex> fun1 = [fn k,v -> {k,v} end, fn _k,v -> v end]
      ...> {:error, error} = fun1 |> reduce_map1_funs
      ...> error |> Exception.message |> String.starts_with?("map/1 function invalid")
      true

  """

  @since "0.1.0"

  @spec reduce_map1_funs(any) :: {:ok, fun1_map} | {:error, error}

  def reduce_map1_funs(funs)

  def reduce_map1_funs(funs) when is_list(funs) do
    with {:ok, funs} <- funs |> list_wrap_flat_just |> validate_map1_funs do
      funs
      |> length
      |> case do
        0 ->
          new_error_result(m: "map/1 functions empty")

        1 ->
          {:ok, funs |> hd}

        _ ->
          fun = fn v -> funs |> Enum.reduce(v, fn f, v -> v |> f.() end) end

          {:ok, fun}
      end
    else
      {:error, %{__exception__: true}} = result -> result
    end
  end

  def reduce_map1_funs(fun) do
    fun |> validate_map1_fun
  end

  @doc ~S"""
  `reduce_map1_funs/1` takes a *map/1*.

  It calls `Plymio.Fontais.Utility.list_wrap_flat_just/1` on the argument and, if there are no functions (i..e empty list) it returns `{:ok, fn v -> v end}`.

  If there are functions, it calls `reduce_map_funs/1`.

  ## Examples

      iex> fun1 = fn v -> v * v end
      ...> {:ok, fun2} = fun1 |> reduce_or_passthru_map1_funs
      ...> 3 |> fun2.()
      9

      iex> fun1 = nil
      ...> {:ok, fun2} = fun1 |> reduce_or_passthru_map1_funs
      ...> 3 |> fun2.()
      3

      iex> fun1 = [fn v -> v + 5 end, fn v -> v - 11 end, fn v -> v * v end]
      ...> {:ok, fun2} = fun1 |> reduce_or_passthru_map1_funs
      ...> 42 |> fun2.()
      1296

  """

  @since "0.1.0"

  @spec reduce_or_passthru_map1_funs(any) :: {:ok, fun1_map} | {:error, error}

  def reduce_or_passthru_map1_funs(funs) do
    funs
    |> list_wrap_flat_just
    |> case do
      [] ->
        {:ok, fn v -> v end}

      funs ->
        funs |> reduce_map1_funs
    end
  end

  @doc ~S"""
  `reduce_map1_funs/1` takes a *map/1*.

  It calls `Plymio.Fontais.Utility.list_wrap_flat_just/1` on the argument and, if there are no functions (i..e empty list) it returns `{:ok, nil}`.

  If there are functions, it calls `reduce_map_funs/1`.

  ## Examples

      iex> fun1 = fn v -> v * v end
      ...> {:ok, fun2} = fun1 |> reduce_or_nil_map1_funs
      ...> 3 |> fun2.()
      9

      iex> fun1 = [nil]
      ...> fun1 |> reduce_or_nil_map1_funs
      {:ok, nil}

      iex> fun1 = [fn v -> v + 5 end, fn v -> v - 11 end, fn v -> v * v end]
      ...> {:ok, fun2} = fun1 |> reduce_or_nil_map1_funs
      ...> 42 |> fun2.()
      1296

  """

  @since "0.1.0"

  @spec reduce_or_nil_map1_funs(any) :: {:ok, fun1_map} | {:ok, nil} | {:error, error}

  def reduce_or_nil_map1_funs(funs) do
    funs
    |> list_wrap_flat_just
    |> case do
      [] ->
        {:ok, nil}

      funs ->
        funs |> reduce_map1_funs
    end
  end
end
