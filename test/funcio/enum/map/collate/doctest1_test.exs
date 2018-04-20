defmodule PlymioFuncioEnumMapCollatePatternDoctest1Test do
  use ExUnit.Case, async: true
  use PlymioFuncioHelperTest
  import Plymio.Funcio.Enum.Map.Collate
  require Plymio.Fontais.Guard

  doctest Plymio.Funcio.Enum.Map.Collate
end
