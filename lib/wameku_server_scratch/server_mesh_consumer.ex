defmodule WamekuServerScratch.ServerMeshConsumer do
  use GenServer
  use AMQP
  require Logger

  def start_link do
    GenServer.start_link(__MODULE__, [], [])
  end

  @exchange    "server_mesh_exchange"
  @queue       ""

  def init(_opts) do
    {:ok, conn} = Connection.open("amqp://guest:guest@localhost")
    {:ok, chan} = Channel.open(conn)
    # Limit unacknowledged messages to 10
    Basic.qos(chan, prefetch_count: 10)
    Queue.declare(chan, @queue, auto_delete: true, exclusive: true)
    Exchange.fanout(chan, @exchange)
    Queue.bind(chan, @queue, @exchange)
    # Register the GenServer process as a consumer
    {:ok, _consumer_tag} = Basic.consume(chan, @queue)
    {:ok, chan}
  end

  # Confirmation sent by the broker after registering this process as a consumer
  def handle_info({:basic_consume_ok, %{consumer_tag: _consumer_tag}}, chan) do
    {:noreply, chan}
  end

  # Sent by the broker when the consumer is unexpectedly cancelled (such as after a queue deletion)
  def handle_info({:basic_cancel, %{consumer_tag: _consumer_tag}}, chan) do
    {:stop, :normal, chan}
  end

  # Confirmation sent by the broker to the consumer process after a Basic.cancel
  def handle_info({:basic_cancel_ok, %{consumer_tag: consumer_tag}}, chan) do
    {:noreply, chan}
  end

  def handle_info({:basic_deliver, payload, %{delivery_tag: tag, redelivered: redelivered}}, chan) do
    spawn fn -> consume(chan, tag, redelivered, payload) end
    {:noreply, chan}
  end

  defp consume(channel, tag, redelivered, payload) do
    try do
      decoded_payload = Poison.decode!(payload)
      Logger.info("popped #{inspect(decoded_payload)}")
      if decoded_payload["disable_client"] do
        WamekuServerScratch.ClientStore.insert(decoded_payload["disable_client"], %{active: false})
      end
      Basic.ack channel, tag
    rescue
      exception ->
        # Requeue unless it's a redelivered message.
        # This means we will retry consuming a message once in case of exception
        # before we give up and have it moved to the error queue
        Basic.reject channel, tag, requeue: not redelivered
        Logger.error "Error decoding payload: #{payload} #{inspect(exception)}"
    end
  end 
end
