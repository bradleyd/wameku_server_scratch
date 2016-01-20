defmodule WamekuServerScratch.ClientStore do
  use GenServer

  defmodule Client do
    defstruct host: :nil, active: true 
  end

  def start_link(table) do
    GenServer.start_link(__MODULE__, table, name: __MODULE__) 
  end

  def init(table) do
    {:ok, ets}  = :dets.open_file(table, [type: :set])
    {:ok, %{name: ets}}
  end

  def insert(key, payload) do
    client = Map.merge(%Client{host: key}, payload)
    data   = {key, client}
    IO.inspect data
    GenServer.call(__MODULE__, {:insert, data})
  end

  def update(key, new_data) do
    GenServer.call(__MODULE__, {:update, key, new_data})
  end

  def lookup(key) do
    GenServer.call(__MODULE__, {:lookup, key})
  end

  def keys(table) do
    find(table, nil, []) 
  end

  defp find(_, :"$end_of_table", acc) do
    {:ok, List.delete(acc, :"$end_of_table") |> Enum.sort}
  end

  defp find(table, nil, acc) do
    next = :dets.first(table)
    find(table, next, [next|acc])
  end

  defp find(table, thing, acc) do
    next = :dets.next(table, thing)
    find(table, next, [next|acc])
  end

  def find_or_create_by_name(name) do
    case lookup(name) do
      { key, attributes} ->
        Map.merge(%Client{host: key}, attributes)
      :error ->
        %Client{}
    end
  end

  def handle_call({:update, key, payload}, _from, state) do
    client = %{}
    modified_client = Map.merge(client, payload)
    results =
    case :dets.insert(state.name, modified_client) do
      true -> {:ok, "inserted"}
      _ -> {:error}
    end 
    {:reply, results, state}
  end
  def handle_call({:insert, payload}, _from, state) do
    results =
    case :dets.insert(state.name, payload) do
      :ok -> {:ok, "inserted"}
      _ -> {:error}
    end 
    {:reply, results, state}
  end
  def handle_call({:lookup, key}, _from, state) do
    results =
    case :dets.lookup(state.name, key) do
      [{^key, token}] -> {key, token}
      [] -> %Client{}
    end 
    {:reply, results, state}
  end
end
