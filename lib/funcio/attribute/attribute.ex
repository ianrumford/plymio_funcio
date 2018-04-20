defmodule Plymio.Funcio.Attribute do
  @moduledoc false

  defmacro __using__(_opts \\ []) do
    quote do
      @plymio_funcio_key_task_sup_pid :task_sup_pid
      @plymio_funcio_key_task_sup_start_link_opts :task_sup_start_link_opts
      @plymio_funcio_key_task_sup_async_stream_opts :task_sup_async_stream_opts

      @plymio_funcio_defaults_task_sup_start_link_opts []

      @plymio_funcio_defaults_task_sup_async_stream_opts [
        timeout: 10000
      ]
    end
  end
end
