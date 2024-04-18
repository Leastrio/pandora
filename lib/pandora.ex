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
        default: [concurrency: 8]
      ],
      batchers: [
        default: [batch_size: 1, concurrency: 1]
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
    end
  end


  # TODO: Implement adding sites to a database table so that future requests do not resolve
  def handle_batch(_, msgs, _, _) do
    Enum.each(msgs, fn msg ->
      {parent, children} = msg.data

      # TODO: Fix urls being added twice to db
      %Pandora.Schema.Entry{url: parent}
      |> Pandora.Repo.insert()

      all = Pandora.Schema.Entry.get_all_matches(children)
      Enum.filter(children, fn c -> c not in all end)
      |> Enum.map(fn url -> Pandora.Queue.enqueue(url) end)
    end)
    msgs
  end

  # TODO: Implement adding all failed websites to a database blacklisted table so that future requests do not resolve if they are in it
  def handle_failed(msgs, _) do
    IO.puts("MESSAGES FAILED!!!")
    IO.inspect(msgs)
    msgs
  end
end
