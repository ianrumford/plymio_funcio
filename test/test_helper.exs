ExUnit.start()

defmodule PlymioFuncioHelperTest do
  defmacro __using__(_opts \\ []) do
    quote do
      use ExUnit.Case, async: true
      import PlymioFuncioHelperTest
    end
  end
end
