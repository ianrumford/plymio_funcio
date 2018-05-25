defmodule Plymio.Funcio.Error do
  @moduledoc false

  require Plymio.Fontais.Vekil.ProxyForomDict, as: PROXYFORMDICT
  use Plymio.Fontais.Attribute

  @codi_opts [
    {@plymio_fontais_key_dict, Plymio.Fontais.Codi.__vekil__()}
  ]

  :defexception_package
  |> PROXYFORMDICT.reify_proxies(@codi_opts)
end
