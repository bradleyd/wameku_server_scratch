defmodule WamekuServerScratch.Config do
  use GenServer

  @wameku_home Application.get_env(:wameku_server_scratch, :home_directory)

  def start_link() do
    start_link([])
  end
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(opts) do
    config = load_config
    {:ok, config}
  end

  def lookup(key) do
    GenServer.call(__MODULE__, {:lookup, key})
  end

  def sighup do
    GenServer.call(__MODULE__, :reread_config)
  end

  def handle_call({:lookup, key}, _from, state) do
    {:reply, Map.get(state, to_string(key)), state}
  end
  def handle_call(:reread_config, _from, state) do
    config = load_config
    {:reply, config, config}
  end

  def load_config do
    config_path = Path.join([@wameku_home, "server", "config", "notifiers.json"])
    Poison.decode!(File.read!(config_path))
  end

end
