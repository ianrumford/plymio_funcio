defmodule Plymio.Funcio.Error do
  @moduledoc false

  require Plymio.Fontais.Vekil, as: VEKIL
  use Plymio.Fontais.Attribute

  @codi_opts [
    {@plymio_fontais_key_vekil, Plymio.Fontais.Codi.__vekil__()}
  ]

  :def_error_complete
  |> VEKIL.reify_proxies(@codi_opts)
end
