defmodule Pandora.Cache do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(_) do
    entries = Pandora.Schema.Entry.get_all() |> MapSet.new()
    invalid = Pandora.Schema.Invalid.get_all() |> MapSet.new()
    {:ok, MapSet.union(entries, invalid)}
  end

  def handle_call({:insert_new, link}, _from, state) do
    if MapSet.member?(state, link) do
      {:reply, false, state}
    else
      {:reply, true, MapSet.put(state, link)}
    end
  end

  def insert_new(link), do: GenServer.call(__MODULE__, {:insert_new, link})
end
