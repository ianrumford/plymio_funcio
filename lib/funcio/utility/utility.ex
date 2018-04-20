defmodule Plymio.Funcio.Utility do
  @moduledoc ~S"""
  General Functions.

  See `Plymio.Funcio` for overview and documentation terms.
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

  import Plymio.Fontais.Utility,
    only: [
      list_wrap_flat_just: 1
    ]

  import Plymio.Funcio.Enum.Map.Collate,
    only: [
      map_collate0_enum: 2
    ]

  @doc ~S"""
  `validate_fun_name/1` checks whether the argument is an `Atom`, returenin `{:ok, argument}` or `{:error, error}`.

  ## Examples

      iex> :fun_one |> validate_fun_name
      {:ok, :fun_one}

      iex> {:error, error} = 42 |> validate_fun_name
      ...> error |> Exception.message
      "fun name invalid, got: 42"

  """

  @since "0.1.0"

  @spec validate_fun_name(any) :: {:ok, atom} | {:error, error}

  def validate_fun_name(name)

  def validate_fun_name(nil) do
    new_error_result(m: "fun name invalid", v: nil)
  end

  def validate_fun_name(name) when is_atom(name) do
    {:ok, name}
  end

  def validate_fun_name(name) do
    new_error_result(m: "fun name invalid", v: name)
  end

  @doc ~S"""
  `validate_fun_names/1` takes a list of fun names and calls `validate_fun_name/1` on each, returning `{:ok, fun_names}` or `{:error, error}`.

  ## Examples

      iex> [:fun_one] |> validate_fun_names
      {:ok, [:fun_one]}

      iex> [:fun_one, :fun_due, :fun_tre] |> validate_fun_names
      {:ok, [:fun_one, :fun_due, :fun_tre]}

      iex> {:error, error} = [:fun_one, 42, "HelloWorld"] |> validate_fun_names
      ...> error |> Exception.message
      "fun name invalid, got: 42"

  """

  @since "0.1.0"

  @spec validate_fun_names(any) :: {:ok, [atom]} | {:error, error}

  def validate_fun_names(names \\ [])

  def validate_fun_names(names) when is_list(names) do
    names |> map_collate0_enum(&validate_fun_name/1)
  end

  def validate_fun_names(names) do
    new_error_result(m: "fun names invalid", v: names)
  end

  @doc ~S"""
  `normalise_fun_name/1` normalise the argument to a function name, returning `{:ok, argument}` or `{:error, error}` if not.

  If the argument is an atom, it is passed through transparently.

  If the argument is a string, it is converted to an atom.

  ## Examples

      iex> :fun_one |> normalise_fun_name
      {:ok, :fun_one}

      iex> "fun_one" |> normalise_fun_name
      {:ok, :fun_one}

      iex> {:error, error} = 42 |> normalise_fun_name
      ...> error |> Exception.message
      "fun name invalid, got: 42"

  """

  @since "0.1.0"

  @spec normalise_fun_name(any) :: {:ok, atom} | {:error, error}

  def normalise_fun_name(name)

  def normalise_fun_name(nil) do
    new_error_result(m: "fun name invalid", v: nil)
  end

  def normalise_fun_name(name) when is_atom(name) do
    {:ok, name}
  end

  def normalise_fun_name(name) when is_binary(name) do
    {:ok, name |> String.to_atom()}
  end

  def normalise_fun_name(name) do
    new_error_result(m: "fun name invalid", v: name)
  end

  @doc ~S"""
  `normalise_fun_names/1` calls
  `Plymio.Fontais.Utility.list_wrap_flat_just/1` on its argument and
  then calls `normalise_fun_name/1` on each, returning `{:ok, fun_names}`
  or `{:error, error}`.

  ## Examples

      iex> [:fun_one] |> normalise_fun_names
      {:ok, [:fun_one]}

      iex> [:fun_one, :fun_due, "fun_tre"] |> normalise_fun_names
      {:ok, [:fun_one, :fun_due, :fun_tre]}

      iex> {:error, error} = [:fun_one, 42, "HelloWorld"] |> normalise_fun_names
      ...> error |> Exception.message
      "fun name invalid, got: 42"

  """

  @since "0.1.0"

  @spec normalise_fun_names(any) :: {:ok, [atom]} | {:error, error}

  def normalise_fun_names(names \\ [])

  def normalise_fun_names(names) do
    names
    |> list_wrap_flat_just
    |> map_collate0_enum(&normalise_fun_name/1)
  end
end
