defmodule UserImporter.Auth0Client.WorkerSupervisor do
  use Supervisor

  defp def_config do
    [size: 5, max_overflow: 0]
  end

  defp management_config do
    def_config() ++
      [worker_module: UserImporter.Auth0Client.Management, name: {:local, :management}]
  end

  defp authorization_config do
    def_config() ++
      [worker_module: UserImporter.Auth0Client.Authorization, name: {:local, :authorization}]
  end

  def start_link do
    GenServer.start_link(__MODULE__, :ok, [])
  end

  def init(:ok) do
    children = [
      :poolboy.child_spec(:management, management_config()),
      :poolboy.child_spec(:authorization, authorization_config())
    ]

    opts = [strategy: :one_for_one, name: __MODULE__]
    Supervisor.start_link(children, opts)
  end
end
