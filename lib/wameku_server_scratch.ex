defmodule WamekuServerScratch do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(WamekuServerScratch.Config, []),
      worker(WamekuServerScratch.CheckConsumer, []),
      worker(WamekuServerScratch.ServerMeshConsumer, [])
    ]

    opts = [strategy: :one_for_one, name: WamekuServerScratch.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
