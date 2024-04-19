defmodule Pandora do
  use Broadway

  alias Broadway.Message

  def start_link(_) do
    Broadway.start_link(__MODULE__,
      name: __MODULE__,
      producer: [
        module: {Pandora.Queue, "https://leastr.io"},
        transformer: {__MODULE__, :transform, []},
        concurrency: 1
      ],
      processors: [
        default: [concurrency: 10]
      ],
      batchers: [
        default: [batch_size: 5, concurrency: 1]
      ]
    )
  end

  def transform(event, _opts) do
    %Message{
      data: event,
      acknowledger: Broadway.NoopAcknowledger.init()
    }
  end

  def handle_message(_, msg, _) do
    case Pandora.Processor.process(msg) do
      {:ok, res} -> msg |> Broadway.Message.put_data(res)
      {:error, reason} -> msg |> Broadway.Message.failed(reason)
      :noop -> msg |> Broadway.Message.put_data(:noop)
    end
  end

  def handle_batch(_, msgs, _, _) do
    Enum.each(msgs, fn msg ->
      if msg.data != :noop do
        {parent, children} = msg.data

        %Pandora.Schema.Entry{url: parent}
        |> Pandora.Repo.insert()

        Enum.map(children, fn url -> Pandora.Queue.enqueue(url) end)
      end
    end)

    msgs
  end

  def handle_failed(msgs, _) do
    Enum.each(msgs, fn msg ->
      %Pandora.Schema.Invalid{url: msg.data}
      |> Pandora.Repo.insert()
    end)

    msgs
  end
end
