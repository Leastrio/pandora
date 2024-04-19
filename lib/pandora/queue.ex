defmodule Pandora.Queue do
  use GenStage

  def init(starting_site) do
    {:producer, {:queue.from_list([starting_site]), 0}}
  end

  def handle_cast({:enqueue, link}, {queue, pending_demand}) do
    dispatch_events(:queue.in(link, queue), pending_demand, [])
  end

  def handle_demand(incoming_demand, {queue, pending_demand}) do
    dispatch_events(queue, incoming_demand + pending_demand, [])
  end

  defp dispatch_events(queue, 0, events) do
    {:noreply, Enum.reverse(events), {queue, 0}}
  end

  defp dispatch_events(queue, demand, events) do
    case :queue.out(queue) do
      {{:value, event}, queue} -> dispatch_events(queue, demand - 1, [event | events])
      {:empty, queue} -> {:noreply, Enum.reverse(events), {queue, demand}}
    end
  end

  def enqueue(link) do
    {_, pid, _, _} =
      Supervisor.which_children(Pandora.Broadway.ProducerSupervisor) |> List.first()

    GenStage.cast(pid, {:enqueue, link})
  end
end
