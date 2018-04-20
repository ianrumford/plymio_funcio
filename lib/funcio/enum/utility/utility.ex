defmodule Plymio.Funcio.Enum.Utility do
  @moduledoc false

  use Plymio.Funcio.Attribute

  @type error :: Plymio.Funcio.error()
  @type fun1_map :: Plymio.Funcio.fun1_map()

  @since "0.1.0"

  @spec enum_reify(any) :: {:ok, list} | {:ok, map} | {:error, error}

  def enum_reify(enum)

  def enum_reify(%Stream{} = enum) do
    try do
      {:ok, enum |> Enum.to_list()}
    rescue
      error ->
        {:error, error}
    end
  end

  def enum_reify(enum)
      when is_list(enum) or is_map(enum) do
    {:ok, enum}
  end

  def enum_reify(enum) do
    try do
      {:ok, enum |> Enum.to_list()}
    rescue
      error ->
        {:error, error}
    end
  end

  @since "0.1.0"

  @spec enum_to_list(any) :: {:ok, list} | {:error, error}

  def enum_to_list(enum)

  def enum_to_list(%Stream{} = enum) do
    try do
      {:ok, enum |> Enum.to_list()}
    rescue
      error ->
        {:error, error}
    end
  end

  def enum_to_list(enum) when is_list(enum) do
    {:ok, enum}
  end

  def enum_to_list(enum) when is_map(enum) do
    {:ok, enum |> Enum.to_list()}
  end

  def enum_to_list(enum) do
    try do
      {:ok, enum |> Enum.to_list()}
    rescue
      error ->
        {:error, error}
    end
  end
end
