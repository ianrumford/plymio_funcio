defmodule Plymio.Funcio.Predicate do
  @moduledoc ~S"""
  Predicate Functions.

  See `Plymio.Funcio` for an overview and documentation terms.
  """

  use Plymio.Funcio.Attribute

  @type key :: Plymio.Funcio.key()
  @type keys :: Plymio.Funcio.keys()
  @type error :: Plymio.Funcio.error()
  @type stream :: Plymio.Funcio.stream()
  @type fun1_predicate :: Plymio.Funcio.fun1_predicate()

  import Plymio.Fontais.Utility,
    only: [
      list_wrap_flat_just: 1
    ]

  import Plymio.Funcio.Predicate.Utility,
    only: [
      validate_predicate1_fun: 1,
      validate_predicate1_funs: 1
    ]

  @doc ~S"""
  `reduce_and_predicate1_funs/1` validates the argument is a one or
  more *predicate/1 functions* and reduces them to a single
  *predicate/1 function*, returning `{:ok, predicate}`.

  Multiple predicates are `AND`-ed together to create a composite
  predicate will return `true` only if **all** of the individual
  predicates return `true`.

  An `AND`-ed predicate can be used with e.g. `Enum.filter/2` or `Enum.reject/2`.

  ## Examples

      iex> predicate1 = fn v -> is_integer(v) end
      ...> {:ok, and_predicate} = predicate1 |> reduce_and_predicate1_funs
      ...> false = :not_an_integer |> and_predicate.()
      ...> false = 3.14 |> and_predicate.()
      ...> true = 42 |> and_predicate.()
      true

      iex> predicates = [
      ...>   fn v -> is_integer(v) end,
      ...>   fn v -> v >= 5 end,
      ...>   fn v -> v < 10 end,
      ...> ]
      ...> {:ok, and_predicate} = predicates |> reduce_and_predicate1_funs
      ...> false = :not_an_integer |> and_predicate.()
      ...> false = 3.14 |> and_predicate.()
      ...> false = 4 |> and_predicate.()
      ...> false = 10 |> and_predicate.()
      ...> true = 5 |> and_predicate.()
      ...> true = 6 .. 9 |> Enum.all?(and_predicate)
      true

      iex> predicates = [fn v -> is_integer(v) end, fn _k,v -> v end]
      ...> {:error, error} = predicates |> reduce_and_predicate1_funs
      ...> error |> Exception.message |> String.starts_with?("predicate/1 function invalid")
      true

  """

  @since "0.1.0"

  @spec reduce_and_predicate1_funs(any) :: {:ok, fun1_predicate} | {:error, error}

  def reduce_and_predicate1_funs(funs)

  def reduce_and_predicate1_funs(funs) when is_list(funs) do
    with {:ok, funs} <- funs |> list_wrap_flat_just |> validate_predicate1_funs do
      funs
      |> length
      |> case do
        1 ->
          {:ok, funs |> hd}

        _ ->
          fun = fn v ->
            funs |> Enum.all?(fn f -> v |> f.() end)
          end

          {:ok, fun}
      end
    else
      {:error, %{__exception__: true}} = result -> result
    end
  end

  def reduce_and_predicate1_funs(fun) do
    fun |> validate_predicate1_fun
  end

  @doc ~S"""
  `reduce_or_predicate1_funs/1` validates the argument is a one or
  more *predicate/1 functions* and reduces them to a single
  *predicate/1 function*, returning `{:ok, predicate}`.

  Multiple predicates are `OR`-ed together to create a composite
  predicate will return `true` if **any** of the individual predicates
  return `true`.

  An `OR`-ed predicate can be used with e.g. `Enum.filter/2`.

  When using a composite `OR` predicate with e.g. `Enum.reject/2`, it
  should be remembered that if **any** of individual predicates
  returns `true`, the composite predicate will return `true` and the
  reject "fail".

  ## Examples

      iex> predicate1 = fn v -> is_integer(v) end
      ...> {:ok, or_predicate} = predicate1 |> reduce_or_predicate1_funs
      ...> false = :not_an_integer |> or_predicate.()
      ...> false = 3.14 |> or_predicate.()
      ...> true = 42 |> or_predicate.()
      true

      iex> predicates = [
      ...>   fn v -> is_atom(v) end,
      ...>   fn v -> is_binary(v) end,
      ...>   fn v -> is_integer(v) && v >= 5 end,
      ...>   fn v -> is_integer(v) && v < 10 end,
      ...> ]
      ...> {:ok, or_predicate} = predicates |> reduce_or_predicate1_funs
      ...> true = :not_an_integer |> or_predicate.()
      ...> true = "Hello World" |> or_predicate.()
      ...> false = 3.14 |> or_predicate.()
      ...> true = 4 |> or_predicate.()
      ...> true = 10 |> or_predicate.()
      ...> true = 5 |> or_predicate.()
      ...> true = 6 .. 9 |> Enum.any?(or_predicate)
      true

      iex> predicates = [fn v -> is_integer(v) end, fn _k,v -> v end]
      ...> {:error, error} = predicates |> reduce_or_predicate1_funs
      ...> error |> Exception.message |> String.starts_with?("predicate/1 function invalid")
      true

  """

  @since "0.1.0"

  @spec reduce_or_predicate1_funs(any) :: {:ok, fun1_predicate} | {:error, error}

  def reduce_or_predicate1_funs(funs)

  def reduce_or_predicate1_funs(funs) when is_list(funs) do
    with {:ok, funs} <- funs |> List.wrap() |> validate_predicate1_funs do
      funs
      |> length
      |> case do
        1 ->
          {:ok, funs |> hd}

        _ ->
          fun = fn v ->
            funs |> Enum.any?(fn f -> v |> f.() end)
          end

          {:ok, fun}
      end
    else
      {:error, %{__exception__: true}} = result -> result
    end
  end

  def reduce_or_predicate1_funs(fun) do
    fun |> validate_predicate1_fun
  end
end
