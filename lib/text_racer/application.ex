defmodule GracefulShutdown do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, [])
  end

  @impl GenServer
  def init(_) do
    Process.flag(:trap_exit, true)
    {:ok, nil}
  end

  @impl GenServer
  def terminate(_, _) do
    IO.puts("I'm terminating")
    :stop
  end
end

defmodule TextRacer.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      TextRacerWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: TextRacer.PubSub},
      # Start the Endpoint (http/https)
      TextRacerWeb.Endpoint,
      {TextRacer.Clock,
       broadcaster: fn -> TextRacerWeb.Endpoint.broadcast("clock", "tick", %{}) end},
      GracefulShutdown
      # Start a worker by calling: TextRacer.Worker.start_link(arg)
      # {TextRacer.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: TextRacer.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    TextRacerWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
