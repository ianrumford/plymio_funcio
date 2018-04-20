defmodule Plymio.Funcio.Predicate.Utility do
  @moduledoc ~S"""
  Predicate Utility Functions.

  See `Plymio.Funcio` for an overview and documentation terms.
  """

  use Plymio.Funcio.Attribute

  @type key :: Plymio.Funcio.key()
  @type keys :: Plymio.Funcio.keys()
  @type error :: Plymio.Funcio.error()
  @type stream :: Plymio.Funcio.stream()
  @type fun1_map :: Plymio.Funcio.fun1_map()
  @type fun1_predicate :: Plymio.Funcio.fun1_predicate()

  import Plymio.Funcio.Error,
    only: [
      new_error_result: 1
    ]

  import Plymio.Funcio.Enum.Map.Collate,
    only: [
      map_collate0_enum: 2
    ]

  @doc ~S"""
  `validate_predicate1_fun/1` validates the argument is an arity 1 function, returning `{:ok, fun}` or `{:error, error}`.

  ## Examples

      iex> fun1 = fn v -> is_integer(v) end
      ...> {:ok, fun2} = fun1 |> validate_predicate1_fun
      ...> fun2 |> is_function(1)
      true

      iex> fun1 = fn _k,v -> v end
      ...> {:error, error} = fun1 |> validate_predicate1_fun
      ...> error |> Exception.message |> String.starts_with?("predicate/1 function invalid")
      true

      iex> fun1 = 42
      ...> {:error, error} = fun1 |> validate_predicate1_fun
      ...> error |> Exception.message
      "predicate/1 function invalid, got: 42"

  """

  @since "0.1.0"

  @spec validate_predicate1_fun(any) :: {:ok, fun1_predicate} | {:error, error}

  def validate_predicate1_fun(fun)

  def validate_predicate1_fun(fun) when is_function(fun, 1) do
    {:ok, fun}
  end

  def validate_predicate1_fun(fun) do
    new_error_result(m: "predicate/1 function invalid", v: fun)
  end

  @doc ~S"""
  `validate_predicate1_funs/1` validates the argument is a list of arity 1 functions, returning `{:ok, funs}` or `{:error, error}`.

  ## Examples

      iex> fun1 = fn v -> is_integer(v) end
      ...> {:error, error} = fun1 |> validate_predicate1_funs
      ...> error |> Exception.message |> String.starts_with?("predicate/1 functions invalid")
      true

      iex> fun1 = [fn v -> is_integer(v) end]
      ...> {:ok, fun2} = fun1 |> validate_predicate1_funs
      ...> fun2 |> Enum.all?(&(is_function(&1,1)))
      true

      iex> fun1 = [fn v -> is_integer(v) end, fn v -> is_atom(v) end]
      ...> {:ok, fun2} = fun1 |> validate_predicate1_funs
      ...> fun2 |> Enum.all?(&(is_function(&1,1)))
      true

      iex> fun1 = [fn v -> is_integer(v) end, fn _k,v -> v end]
      ...> {:error, error} = fun1 |> validate_predicate1_funs
      ...> error |> Exception.message |> String.starts_with?("predicate/1 function invalid")
      true

  """

  @since "0.1.0"

  @spec validate_predicate1_funs(any) :: {:ok, [fun1_predicate]} | {:error, error}

  def validate_predicate1_funs(funs)

  def validate_predicate1_funs(funs) when is_list(funs) do
    with {:ok, _funs} = result <-
           funs
           |> map_collate0_enum(&validate_predicate1_fun/1) do
      result
    else
      {:error, %{__exception__: true}} = result -> result
    end
  end

  def validate_predicate1_funs(funs) do
    new_error_result(m: "predicate/1 functions invalid", v: funs)
  end
end
