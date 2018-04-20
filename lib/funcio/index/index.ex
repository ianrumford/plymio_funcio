defmodule Plymio.Funcio.Index do
  @moduledoc ~S"""
  Utility Functions for Indices

  ## Documentation Terms

  See also `Plymio.Funcio` for an overview and other documentation terms.

  ### *index*

  An *index* is an integer

  ### *indices*

  An *indices* is a list of *index*

  ### *index range*

  An *index range* is a specification for an *indices*.

  It can include integers, integer ranges, lists of integers or an
  enumerable that realises to a list of integers.

  Examples are:

      0
      -2
      1 .. 5
      [99, 1, 2, -1, -2, 4, -1, 0]
      [0 .. 4, [5 , 6], 7 .. 9]
      0 .. 9 |> Stream.map(&(&1))
      [0 .. 4, [5 , 6], 7 .. 9, 0 .. 9, 0 .. 9 |> Stream.map(&(&1))]

  """

  import Plymio.Funcio.Error,
    only: [
      new_error_result: 1
    ]

  import Plymio.Fontais.Utility,
    only: [
      list_wrap_flat_just: 1
    ]

  import Plymio.Fontais.Guard,
    only: [
      is_positive_integer: 1
    ]

  import Plymio.Funcio.Enum.Map.Collate,
    only: [
      map_collate0_enum: 2
    ]

  @type error :: Plymio.Funcio.error()
  @type index :: Plymio.Funcio.index()
  @type indices :: Plymio.Funcio.indices()
  @type fun1_predicate :: Plymio.Funcio.fun1_predicate()

  @error_text_index_invalid "index invalid"
  @error_text_index_range_invalid "index range invalid"
  @error_text_indices_invalid "indices invalid"

  @doc ~S"""
  `validate_index/1` takes a value and validates it is an integer, returning
  `{:ok, index}`, otherwise `{:error, error}`

  ## Examples

      iex> 1 |> validate_index
      {:ok, 1}

      iex> {:error, error} = [1,2,3] |> validate_index
      ...> error |> Exception.message
      "index invalid, got: [1, 2, 3]"

      iex> {:error, error} = :not_an_index |> validate_index
      ...> error |> Exception.message
      "index invalid, got: :not_an_index"

  """

  @since "0.1.0"

  @spec validate_index(any) :: {:ok, index} | {:error, error}

  def validate_index(index)

  def validate_index(index) when is_integer(index) do
    {:ok, index}
  end

  def validate_index(index) do
    new_error_result(m: @error_text_index_invalid, v: index)
  end

  @doc false

  def new_index_error_result(index)

  def new_index_error_result(index) do
    index
    |> List.wrap()
    |> length
    |> case do
      1 ->
        new_error_result(m: @error_text_index_invalid, v: index |> hd)

      _ ->
        new_error_result(m: @error_text_indices_invalid, v: index)
    end
  end

  @doc ~S"""
  `validate_indices/1` takes a list and validates each element is an integer, returning
  `{:ok, indices}`, otherwise `{:error, error}`

  ## Examples

      iex> [1,2,3] |> validate_indices
      {:ok, [1,2,3]}

      iex> {:error, error} = 42 |> validate_indices
      ...> error |> Exception.message
      "indices invalid, got: 42"

      iex> {:error, error} = [1,:b,3] |> validate_indices
      ...> error |> Exception.message
      "index invalid, got: :b"

      iex> {:error, error} = [1,:b,:c] |> validate_indices
      ...> error |> Exception.message
      "indices invalid, got: [:b, :c]"

      iex> {:error, error} = 42 |> validate_indices
      ...> error |> Exception.message
      "indices invalid, got: 42"

  """

  @since "0.1.0"

  @spec validate_indices(any) :: {:ok, indices} | {:error, error}

  def validate_indices(indices)

  def validate_indices(indices) when is_list(indices) do
    indices
    |> Enum.split_with(&is_integer/1)
    |> case do
      {indices, []} ->
        {:ok, indices}

      {_, others} ->
        others |> new_index_error_result
    end
  end

  def validate_indices(indices) do
    new_error_result(m: @error_text_indices_invalid, v: indices)
  end

  @doc ~S"""
  `validate_positive_indices/1` takes a list and validates each element is a postive integer,
  returning `{:ok, indices}`, otherwise `{:error, error}`

  ## Examples

      iex> [1,2,3] |> validate_positive_indices
      {:ok, [1,2,3]}

      iex> {:error, error} = [1,-1,2] |> validate_positive_indices
      ...> error |> Exception.message
      "index invalid, got: -1"

      iex> {:error, error} = 42 |> validate_positive_indices
      ...> error |> Exception.message
      "indices invalid, got: 42"

      iex> {:error, error} = [1,:b,3] |> validate_positive_indices
      ...> error |> Exception.message
      "index invalid, got: :b"

      iex> {:error, error} = [1,:b,:c] |> validate_positive_indices
      ...> error |> Exception.message
      "indices invalid, got: [:b, :c]"

  """

  @since "0.1.0"

  @spec validate_positive_indices(any) :: {:ok, indices} | {:error, error}

  def validate_positive_indices(indices)

  def validate_positive_indices(indices) when is_list(indices) do
    indices
    |> Enum.split_with(&is_positive_integer/1)
    |> case do
      {indices, []} ->
        {:ok, indices}

      {_, others} ->
        others |> new_index_error_result
    end
  end

  def validate_positive_indices(indices) do
    new_error_result(m: @error_text_indices_invalid, v: indices)
  end

  @doc ~S"""
  `normalise_indices/1` calls `Plymio.Fontais.Utility.list_wrap_flat_just/1`
   on ist argument and then calls
  `validate_indices/1`, returning `{:ok, indices}`, otherwise
  `{:error, error}`

  ## Examples

      iex> [1,2,3] |> normalise_indices
      {:ok, [1,2,3]}

      iex> 42 |> normalise_indices
      {:ok, [42]}

      iex> {:error, error} = [1,:b,3] |> normalise_indices
      ...> error |> Exception.message
      "index invalid, got: :b"

      iex> {:error, error} = [1,:b,:c] |> normalise_indices
      ...> error |> Exception.message
      "indices invalid, got: [:b, :c]"

      iex> {:error, error} = :not_an_index |> normalise_indices
      ...> error |> Exception.message
      "index invalid, got: :not_an_index"

  """

  @since "0.1.0"

  @spec normalise_indices(any) :: {:ok, indices} | {:error, error}

  def normalise_indices(indices) do
    indices
    |> list_wrap_flat_just
    |> validate_indices
  end

  @doc ~S"""
  `normalise_index_range/1` takes an *index range* and realises it to return `{:ok, indices}`.

  ## Examples

      iex> 1 |> normalise_index_range
      {:ok, [1]}

      iex> -2 |> normalise_index_range
      {:ok, [-2]}

      iex> [1,2,3,3,1,2] |> normalise_index_range
      {:ok, [1,2,3,3,1,2]}

      iex> 0 .. 4 |> normalise_index_range
      {:ok, [0,1,2,3,4]}

      iex> 0 .. 9 |> Stream.map(&(&1))  |> normalise_index_range
      {:ok, [0,1,2,3,4,5,6,7,8,9]}

      iex> [0 .. 4, [5 , 6], 7 .. 9, 0 .. 9, 0 .. 9 |> Stream.map(&(&1))]
      ...> |> normalise_index_range
      {:ok, [0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8,9]}

      iex> {:error, error} = :not_valid |> normalise_index_range
      ...> error |> Exception.message
      "index range invalid, got: :not_valid"

  """

  @since "0.1.0"

  @spec normalise_index_range(any) :: {:ok, indices} | {:error, error}

  def normalise_index_range(indices)

  def normalise_index_range(index_range) when is_integer(index_range) do
    {:ok, [index_range]}
  end

  def normalise_index_range(%Stream{} = index_range) do
    index_range
    |> Enum.to_list()
    |> normalise_index_range
  end

  def normalise_index_range(_.._ = index_range) do
    index_range
    |> Enum.to_list()
    |> normalise_index_range
  end

  def normalise_index_range(index_range) when is_map(index_range) do
    index_range
    |> Map.keys()
    |> normalise_index_range
  end

  def normalise_index_range(index_range)
      when is_atom(index_range) do
    index_range
    |> case do
      :first ->
        0 |> normalise_index_range

      :last ->
        -1 |> normalise_index_range

      x ->
        new_error_result(m: @error_text_index_range_invalid, v: x)
    end
  end

  def normalise_index_range(index_range) when is_list(index_range) do
    cond do
      Keyword.keyword?(index_range) ->
        index_range
        |> Keyword.values()
        |> normalise_index_range

      true ->
        index_range
        |> map_collate0_enum(fn index ->
          index
          |> normalise_index_range
          |> case do
            {:error, %{__struct__: _}} ->
              new_error_result(m: @error_text_index_invalid, v: index)

            {:ok, _} = result ->
              result
          end
        end)
        |> case do
          {:error, %{__exception__: true}} = result -> result
          {:ok, indices} -> indices |> normalise_indices
        end
    end
  end

  def normalise_index_range(index_range) do
    new_error_result(m: @error_text_index_range_invalid, v: index_range)
  end

  @doc ~S"""
  `create_predicate_indices/1` takes an *indices* and creates an arity 1 function that expects to be passed a `{value, index}` 2tuple and returns `true` if the `index` is in the *indices*, else `false`.

  ## Examples

      iex> {:ok, fun} = [0,1,2] |> create_predicate_indices
      ...> true = {:x, 0} |> fun.()
      ...> true = {%{a: 1}, 2} |> fun.()
      ...> true = {42, 2} |> fun.()
      ...> {"HelloWorld", 4} |> fun.()
      false

      iex> {:error, error} = :not_valid |> create_predicate_indices
      ...> error |> Exception.message
      "indices invalid, got: :not_valid"

  """

  @since "0.1.0"

  @spec create_predicate_indices(any) :: {:ok, fun1_predicate} | {:error, error}

  def create_predicate_indices(indices) do
    with {:ok, indices} <- indices |> validate_indices do
      indices_map = indices |> Map.new(fn k -> {k, nil} end)

      fun = fn
        {_form, index} ->
          indices_map |> Map.has_key?(index)

        x ->
          raise ArgumentError,
            message: "predicate argument {form,index} invalid; got #{inspect(x)}"
      end

      {:ok, fun}
    else
      {:error, %{__exception__: true}} = result -> result
    end
  end

  @doc ~S"""
  `create_predicate_index_range/1` takes  *index range* and creates an arity 1 function that expects to be passed a `{value, index}` 2tuple and returns `true` if the `index` is in the *index range*, else `false`.

  If the *index range* is an arity 1 function, it is "wrapped" to ensure the result is always `true` or `false`.

  If the *index range* is `nil` an always `true` predicate will be returned.

  Note negative indices will cause an error.

  ## Examples

      iex> {:ok, fun} = 42 |> create_predicate_index_range
      ...> true = {:x, 42} |> fun.()
      ...> {"HelloWorld", 4} |> fun.()
      false

      iex> {:ok, fun} = [0,1,2] |> create_predicate_index_range
      ...> true = {:x, 0} |> fun.()
      ...> true = {%{a: 1}, 2} |> fun.()
      ...> true = {42, 2} |> fun.()
      ...> {"HelloWorld", 4} |> fun.()
      false

      iex> {:error, error} = [-2,0,-1] |> create_predicate_index_range
      ...> error |> Exception.message
      "indices invalid, got: [-2, -1]"

      iex> {:ok, fun} = 0 .. 2 |> create_predicate_index_range
      ...> true = {:x, 0} |> fun.()
      ...> true = {%{a: 1}, 2} |> fun.()
      ...> true = {42, 2} |> fun.()
      ...> {"HelloWorld", 4} |> fun.()
      false

      iex> {:ok, fun} = fn _ -> false end |> create_predicate_index_range
      ...> false = {:x, 0} |> fun.()
      ...> false = {%{a: 1}, 2} |> fun.()
      ...> false = {42, 2} |> fun.()
      ...> {"HelloWorld", 4} |> fun.()
      false

      iex> {:ok, fun} = fn _ -> 42 end |> create_predicate_index_range
      ...> true = {:x, 0} |> fun.()
      ...> true = {%{a: 1}, 2} |> fun.()
      ...> true = {42, 2} |> fun.()
      ...> {"HelloWorld", 4} |> fun.()
      true

      iex> {:ok, fun} = nil |> create_predicate_index_range
      ...> true = {:x, 0} |> fun.()
      ...> true = {%{a: 1}, 2} |> fun.()
      ...> true = {42, 2} |> fun.()
      ...> {"HelloWorld", 4} |> fun.()
      true

      iex> {:error, error} = :not_valid |> create_predicate_index_range
      ...> error |> Exception.message
      "index range invalid, got: :not_valid"

  """

  @since "0.1.0"

  @spec create_predicate_index_range(any) :: {:ok, fun1_predicate} | {:error, error}

  def create_predicate_index_range(index_range)

  # range = arity 1 fun
  def create_predicate_index_range(index_range) when is_function(index_range, 1) do
    # ensure true / false
    fun = fn v ->
      v
      |> index_range.()
      |> case do
        x when x in [nil, false] -> false
        _ -> true
      end
    end

    {:ok, fun}
  end

  # nil => always true
  def create_predicate_index_range(index_range) when is_nil(index_range) do
    {:ok, fn _ -> true end}
  end

  def create_predicate_index_range(index_range) do
    with {:ok, range_indices} <- index_range |> normalise_index_range,
         {:ok, positive_indices} <- range_indices |> validate_positive_indices,
         {:ok, _fun} = result <- positive_indices |> create_predicate_indices do
      result
    else
      {:error, %{__exception__: true}} = result -> result
    end
  end
end
