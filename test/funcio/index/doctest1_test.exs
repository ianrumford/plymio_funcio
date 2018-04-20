defmodule PlymioFuncioIndexDoctest1Test do
  use ExUnit.Case, async: true
  use PlymioFuncioHelperTest
  import Plymio.Funcio.Index

  doctest Plymio.Funcio.Index
end
