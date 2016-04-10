defmodule WamekuServerScratch.CheckConsumer do
  use GenServer
  use Database
  use AMQP
  require Logger

  @amqp Application.get_env(:wameku_server_scratch, :amqp)

  defmodule State do
    defstruct channel: :nil, connection: :nil
  end

  def start_link do
    GenServer.start_link(__MODULE__, [], [])
  end

  def init(_opts) do
    {:ok, conn} = Connection.open(heartbeat: 60, host: @amqp.host, port: 5672, username: @amqp.username, password: @amqp.password, virtual_host: @amqp.virtual_host)
    {:ok, chan} = Channel.open(conn)
    queue       = @amqp.queue_name
    queue_error = "#{queue}_error"
    exchange    = @amqp.exchange_name
    # Limit unacknowledged messages to 10
    Basic.qos(chan, prefetch_count: 10)
    Queue.declare(chan, queue_error, durable: true)
    # Messages that cannot be delivered to any consumer in the main queue will be routed to the error queue
    Queue.declare(chan, queue, durable: true,
    arguments: [{"x-dead-letter-exchange", :longstr, ""},
      {"x-dead-letter-routing-key", :longstr, queue_error}])
    Exchange.direct(chan, exchange, durable: true)
    Queue.bind(chan, queue, exchange)
    # Register the GenServer process as a consumer
    {:ok, _consumer_tag} = Basic.consume(chan, queue)
    {:ok, %State{channel: chan, connection: conn}}
  end

  # Confirmation sent by the broker after registering this process as a consumer
  def handle_info({:basic_consume_ok, %{consumer_tag: _consumer_tag}}, state) do
    {:noreply, state}
  end

  # Sent by the broker when the consumer is unexpectedly cancelled (such as after a queue deletion)
  def handle_info({:basic_cancel, %{consumer_tag: _consumer_tag}}, state) do
    {:stop, :normal, state}
  end

  # Confirmation sent by the broker to the consumer process after a Basic.cancel
  def handle_info({:basic_cancel_ok, %{consumer_tag: consumer_tag}}, state) do
    {:noreply, state}
  end

  def handle_info({:basic_deliver, payload, %{delivery_tag: tag, redelivered: redelivered}}, state) do
    spawn fn -> consume(state, tag, redelivered, payload) end
    {:noreply, state}
  end

  defp consume(state, tag, redelivered, payload) do
    #try do
      decoded_payload = Poison.decode!(payload)
      Logger.info("popped check #{inspect(decoded_payload)}")
      incoming = %{host: decoded_payload["host"]}
      case Client.find(decoded_payload["host"]) do
        nil ->
          Client.insert(%Client{name: decoded_payload["host"], active: true, notifier: decoded_payload["notifier"], last_checked: decoded_payload["last_checked"]})
        client ->
          Client.insert(%Client{client | notifier: decoded_payload["notifier"], last_checked: decoded_payload["last_checked"]})
      end
      handle_info = WamekuServerScratch.CheckHandler.handle(decoded_payload)
      Logger.debug("Check Handler: #{inspect(handle_info)}")
      Basic.ack state.channel, tag
      #rescue
        #exception ->
        # Requeue unless it's a redelivered message.
        # This means we will retry consuming a message once in case of exception
        # before we give up and have it moved to the error queue
        #Basic.reject state.channel, tag, requeue: not redelivered
        #Logger.error "Error decoding payload: #{payload} #{inspect(exception)}"
    #end
  end
end
