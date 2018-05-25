defmodule Plymio.Funcio.Enum.Collate do
  @moduledoc ~S"""
  Collate Patterns for Enumerables.

  These functions collate the elements of an *enum* according to one of the defined *patterns*.

  See `Plymio.Funcio` for overview and documentation terms.
  """

  use Plymio.Funcio.Attribute

  @type error :: Plymio.Funcio.error()

  import Plymio.Fontais.Error,
    only: [
      new_argument_error_result: 1
    ]

  import Plymio.Fontais.Guard,
    only: [
      is_value_unset_or_nil: 1
    ]

  @doc ~S"""
  `collate0_enum/2` takes an *enum* and collates its elements according to *pattern 0*.

  If an element is `{:ok, value}`, the `value` is added to the
  accumulated list of `values` and `{:ok, values}` is returned.

  If any element is `{:error, error}` or `value`, the collation is
  halted, returning `{:error, error}`.

  ## Examples

      iex> enum = [{:ok, 1}, {:ok, 2}, {:ok, 3}]
      ...> enum |> collate0_enum
      {:ok, [1, 2, 3]}

      iex> enum = [{:ok, 1}, {:error, %ArgumentError{message: "value is 2"}}, {:ok, 3}]
      ...> {:error, error} = enum |> collate0_enum
      ...> error |> Exception.message
      "value is 2"

      iex> {:error, error} = :not_an_enum |> collate0_enum
      ...> error |> Exception.message
      ...> |> String.starts_with?("protocol Enumerable not implemented for :not_an_enum")
      true

  """

  @since "0.1.0"

  @spec collate0_enum(any) :: {:ok, list} | {:error, error}

  def collate0_enum(enum) do
    try do
      enum
      |> Enum.reduce_while(
        [],
        fn value, values ->
          value
          |> case do
            {:ok, value} -> {:cont, [value | values]}
            {:error, %{__struct__: _}} = result -> {:halt, result}
            value -> {:halt, new_argument_error_result(m: "pattern0 result invalid", v: value)}
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
  end

  @doc ~S"""
  `collate1_enum/2` takes an *enum* and collates its elements according to *pattern 1*.

  If an element is `{:ok, value}` or `value`, the `value` is added to
  the accumulated list of `values` and `{:ok, values}` is returned.

  If any element is `{:error, error}` the collation is halted, returning the `{:error, error}`.

  ## Examples

      iex> [:a, 2, {:ok, :tre}] |> collate1_enum
      {:ok, [:a, 2, :tre]}

      iex> enum = [{:ok, 1}, {:error, %ArgumentError{message: "value is 2"}}, {:ok, 3}]
      ...> {:error, error} = enum |> collate1_enum
      ...> error |> Exception.message
      "value is 2"

      iex> {:error, error} = :not_an_enum |> collate1_enum
      ...> error |> Exception.message
      ...> |> String.starts_with?("protocol Enumerable not implemented for :not_an_enum")
      true

  """

  @since "0.1.0"

  @spec collate1_enum(any) :: {:ok, list} | {:error, error}

  def collate1_enum(enum) do
    try do
      enum
      |> Enum.reduce_while(
        [],
        fn value, values ->
          value
          |> case do
            {:ok, value} -> {:cont, [value | values]}
            {:error, %{__struct__: _}} = result -> {:halt, result}
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
  end

  @doc ~S"""
  `collate2_enum/1` takes an *enum* and collates its elements according to *pattern 2*.

  If an element is `{:ok, value}` or `value`, the `value` is added to
  the accumulated list of `values` and `{:ok, values}` is returned.

  If an element is `nil` or *the unset value* (see `Plymio.Fontais`),
  the element is dropped and **not** added to the accumulated `values`.

  If any element is `{:error, error}` the collation is halted, returning the `{:error, error}`.

  ## Examples

      iex> [{:ok, :a}, nil, {:ok, :tre}] |> collate2_enum
      {:ok, [:a, :tre]}

      iex> unset_value = Plymio.Fontais.Guard.the_unset_value
      ...> [unset_value, nil, {:ok, :a}, nil, {:ok, :tre}, unset_value] |> collate2_enum
      {:ok, [:a, :tre]}

      iex> unset_value = Plymio.Fontais.Guard.the_unset_value
      ...> [unset_value, nil, {:ok, :a}, nil, :b, {:ok, :c}, unset_value, :d] |> collate2_enum
      {:ok, [:a, :b, :c, :d]}

      iex> unset_value = Plymio.Fontais.Guard.the_unset_value
      ...> enum = [unset_value, {:ok, 1}, nil, {:error, %ArgumentError{message: "value is 2"}}, {:ok, 3}]
      ...> {:error, error} = enum |> collate2_enum
      ...> error |> Exception.message
      "value is 2"

      iex> {:error, error} = :not_an_enum |> collate2_enum
      ...> error |> Exception.message
      ...> |> String.starts_with?("protocol Enumerable not implemented for :not_an_enum")
      true

  """

  @since "0.1.0"

  @spec collate2_enum(any) :: {:ok, list} | {:error, error}

  def collate2_enum(enum) do
    try do
      enum
      |> Enum.reduce_while(
        [],
        fn value, values ->
          value
          |> case do
            {:ok, value} -> {:cont, [value | values]}
            {:error, %{__struct__: _}} = result -> {:halt, result}
            value when is_value_unset_or_nil(value) -> {:cont, values}
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
  end
end
