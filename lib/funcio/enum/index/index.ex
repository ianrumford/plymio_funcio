defmodule Plymio.Funcio.Enum.Index do
  @moduledoc ~S"""
  Functions for an Enumerable's Indices

  ## Documentation Terms

  ### *index range*

  See `Plymio.Funcio.Index` for an explanation of *index range*

  See `Plymio.Funcio` for an overview and explanation of other terms used in the documentation.
  """

  import Plymio.Fontais.Error,
    only: [
      new_error_result: 1
    ]

  import Plymio.Funcio.Index,
    only: [
      normalise_index_range: 1,
      validate_index: 1,
      validate_indices: 1,
      new_index_error_result: 1,
      create_predicate_indices: 1
    ]

  import Plymio.Funcio.Enum.Utility,
    only: [
      enum_to_list: 1
    ]

  @type error :: Plymio.Funcio.error()
  @type index :: Plymio.Funcio.index()
  @type indices :: Plymio.Funcio.indices()
  @type fun1_predicate :: Plymio.Funcio.fun1_predicate()

  @error_text_list_invalid "list invalid"

  defp list_indices(state) when is_list(state) do
    Range.new(0, length(state) - 1)
  end

  @doc ~S"""
  `normalise_index_range_enum/1` takes an *enum* and *index range*,
  normalises the *index range* and converts negative indices to their
  absolute (zero offset) values.

  Finally it confirms each index is valid for the *enum*, returning `{:ok, positive_indices}`.

  ## Examples

      iex> [1,2,3] |> normalise_index_range_enum(0)
      {:ok, [0]}

      iex> [1,2,3] |> normalise_index_range_enum(-1)
      {:ok, [2]}

      iex> [1,2,3] |> normalise_index_range_enum([0,-1])
      {:ok, [0,2]}

      iex> [1,2,3] |> normalise_index_range_enum(0 .. 2)
      {:ok, [0,1,2]}

      iex> [1,2,3] |> normalise_index_range_enum([0,-1,0,2])
      {:ok, [0,2,0,2]}

      iex> {:error, error} = [1,2,3] |> normalise_index_range_enum(4)
      ...> error |> Exception.message
      "index invalid, got: 4"

      iex> {:error, error} = [1,2,3] |> normalise_index_range_enum([0,-1,4,5,0,2])
      ...> error |> Exception.message
      "indices invalid, got: [4, 5]"

      iex> {:error, error} = [1,2,3] |> normalise_index_range_enum(:not_valid)
      ...> error |> Exception.message
      "index range invalid, got: :not_valid"

  """

  @since "0.1.0"

  @spec normalise_index_range_enum(any, any) :: {:ok, indices} | {:error, error}

  def normalise_index_range_enum(enum, index_range)

  def normalise_index_range_enum(state, nil) when is_list(state) do
    {:ok, state |> list_indices |> Enum.to_list()}
  end

  def normalise_index_range_enum(state, index_range) do
    with {:ok, indices} <- index_range |> normalise_index_range,
         {:ok, state} <- state |> enum_to_list,
         {:ok, _} = result <- state |> validate_indices_enum(indices) do
      result
    else
      {:error, %{__exception__: true}} = result -> result
    end
  end

  @doc ~S"""
  `validate_index_enum/2` takes an *enum* and *index*, converts
  the *index* into its absolute (zero offset) value and then
  confirms the index is valid for the *enum*, returning
  `{:ok, positive_index}`.

  ## Examples

      iex> [1,2,3] |> validate_index_enum(0)
      {:ok, 0}

      iex> [1,2,3] |> validate_index_enum(-1)
      {:ok, 2}

      iex> {:error, error} = [1,2,3] |> validate_index_enum(4)
      ...> error |> Exception.message
      "index too large, got: 4"

      iex> {:error, error} = [1,2,3] |> validate_index_enum(-999)
      ...> error |> Exception.message
      "index too small, got: -999"

      iex> {:error, error} = [1,2,3] |> validate_index_enum(:not_valid)
      ...> error |> Exception.message
      "index invalid, got: :not_valid"

  """

  @spec validate_index_enum(any, any) :: {:ok, index} | {:error, error}

  def validate_index_enum(enum, index)

  def validate_index_enum(state, index) when is_list(state) do
    with {:ok, index} <- index |> validate_index do
      index_max = length(state) - 1

      case index do
        x when x >= 0 -> x
        x -> index_max + x + 1
      end
      |> case do
        ndx when ndx < 0 ->
          new_error_result(m: "index too small", v: index)

        ndx when ndx > index_max ->
          new_error_result(m: "index too large", v: index)

        ndx ->
          {:ok, ndx}
      end
    else
      {:error, %{__exception__: true}} = result -> result
    end
  end

  def validate_index_enum(state, index) do
    with {:ok, state} <- state |> enum_to_list,
         {:ok, _} = result <- state |> validate_index_enum(index) do
      result
    else
      {:error, %{__exception__: true}} = result -> result
    end
  end

  @doc ~S"""
  `validate_indices_enum/2` takes an *enum* and *indices*, converts
  negative indices into their absolute (zero offset) values and then
  confirms each index is valid for the *enum*, returning
  `{:ok, positive_indices}`.

  ## Examples

      iex> [1,2,3] |> validate_indices_enum(0)
      {:ok, [0]}

      iex> [1,2,3] |> validate_indices_enum(-1)
      {:ok, [2]}

      iex> [1,2,3,4,5] |> validate_indices_enum([-1,0,2])
      {:ok, [4,0,2]}

      iex> {:error, error} = [1,2,3] |> validate_indices_enum(4)
      ...> error |> Exception.message
      "index invalid, got: 4"

      iex> {:error, error} = [1,2,3] |> validate_indices_enum([0,-1,4,5,0,2])
      ...> error |> Exception.message
      "indices invalid, got: [4, 5]"

      iex> {:error, error} = [1,2,3] |> validate_indices_enum(:not_valid)
      ...> error |> Exception.message
      "index invalid, got: :not_valid"

  """

  @since "0.1.0"

  @spec validate_indices_enum(any, any) :: {:ok, indices} | {:error, error}

  def validate_indices_enum(enum, indices)

  def validate_indices_enum(state, indices) when is_list(state) do
    with {:ok, state} <- state |> enum_to_list,
         {:ok, indices} <- indices |> List.wrap() |> validate_indices do
      indices
      |> Enum.reduce(
        {[], []},
        fn index, {oks, errors} ->
          state
          |> validate_index_enum(index)
          |> case do
            {:ok, index} -> {[index | oks], errors}
            {:error, %{__struct__: _}} -> {oks, [index | errors]}
          end
        end
      )
      |> case do
        # no invalid indices
        {indices, []} ->
          {:ok, indices |> Enum.reverse()}

        {_, invalid_indices} ->
          invalid_indices |> Enum.reverse() |> new_index_error_result
      end
    else
      {:error, %{__exception__: true}} = result -> result
    end
  end

  def validate_indices_enum(state, _indices) do
    new_error_result(m: @error_text_list_invalid, v: state)
  end

  @doc ~S"""
  `create_predicate_index_range_enum/1` takes an *enum* and *index range*
  and creates an arity 1 function that expects to be passed a `{value, index}`
  2tuple and returns `true` if `index` is in the *index range*, else `false`.

  ## Examples

      iex> {:ok, fun} = [1,2,3] |> create_predicate_index_range_enum(0)
      ...> true = {:x, 0} |> fun.()
      ...> {"HelloWorld", 2} |> fun.()
      false

      iex> {:ok, fun} = 0 .. 9 |> Enum.to_list |> create_predicate_index_range_enum(0 .. 2)
      ...> true = {:x, 0} |> fun.()
      ...> true = {%{a: 1}, 2} |> fun.()
      ...> true = {42, 2} |> fun.()
      ...> {"HelloWorld", 4} |> fun.()
      false

      iex> {:error, error} = [] |> create_predicate_index_range_enum(:not_valid)
      ...> error |> Exception.message
      "index range invalid, got: :not_valid"

  """

  @since "0.1.0"

  @spec create_predicate_index_range_enum(any, any) :: {:ok, fun1_predicate} | {:error, error}

  def create_predicate_index_range_enum(enum, index_range \\ nil)

  # range == nil => all state
  def create_predicate_index_range_enum(_state, nil) do
    {:ok, fn _ -> true end}
  end

  # range = arity 1 fun
  def create_predicate_index_range_enum(_state, range)
      when is_function(range, 1) do
    {:ok, range}
  end

  def create_predicate_index_range_enum(state, index_range) do
    with {:ok, range_indices} <- state |> normalise_index_range_enum(index_range),
         {:ok, _fun} = result <- range_indices |> create_predicate_indices do
      result
    else
      {:error, %{__exception__: true}} = result -> result
    end
  end
end
