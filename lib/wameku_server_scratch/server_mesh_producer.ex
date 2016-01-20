defmodule WamekuClientScratch.ServerMeshProducer do
use GenServer  
  use AMQP
  require Logger

  @exchange    "server_mesh_exchange"
  @queue       ""

  defmodule State do
    defstruct channel: :nil
  end

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init([]) do
    {:ok, conn} = AMQP.Connection.open
    {:ok, chan} = AMQP.Channel.open(conn)
    #Queue.declare(chan, @queue)
    Exchange.fanout(chan, @exchange)
    #Queue.bind(chan, @queue, @exchange)
    {:ok, %State{channel: chan}}
  end

  def handle_cast({:publish, message}, state) do
    # serialize message
    serialized_message = Poison.encode!(message)
    case AMQP.Basic.publish(state.channel, @exchange, "", serialized_message) do
      :ok ->
        Logger.info("Published message #{inspect(message)} to queue")
      error ->
        Logger.error("Caught error while publishing message to queue")
    end
    {:noreply, state}
  end
end
