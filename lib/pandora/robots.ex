defmodule Pandora.Robots do
  use GenServer

  @headers [user_agent: "PandoraBot/#{Mix.Project.config()[:version]} (https://github.com/Leastrio/pandora)"]

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(_) do
    {:ok, {%{}, %{}}}
  end

  def handle_call({:getch, uri}, from, {cached, pending} = state) do
    case cached[uri.host] do
      nil -> case pending[uri.host] do
        nil ->
          fetch_robots(uri)
          {:noreply, {cached, Map.put(pending, uri.host, [from])}}
        waiting_pids -> {:noreply, {cached, Map.put(pending, uri.host, [from | waiting_pids])}}
      end
      res -> {:reply, res, state}
    end
  end

  def handle_info({_, {:update, uri, content}}, {cached, pending}) do
    Enum.each(pending[uri.host], fn from -> GenServer.reply(from, content) end)
    {:noreply, {Map.put(cached, uri.host, content), Map.delete(pending, uri.host)}}
  end

  def handle_info(_, state), do: {:noreply, state}

  defp fetch_robots(uri) do
    Task.async(fn ->
      resp = case Req.get("#{uri.scheme}://#{uri.host}/robots.txt", headers: @headers) do
        {:ok, %{status: 200, body: body}} -> __MODULE__.Parser.parse(body)
        {:error, _} -> :invalid
        _ -> %{}
      end
      {:update, uri, resp}
    end)
  end

  def check(uri) do
    case GenServer.call(__MODULE__, {:getch, uri}, :infinity) do
      :invalid -> {:error, :invalid}
      m when map_size(m) == 0 -> :ok
      m -> __MODULE__.Parser.is_allowed(m, uri)
    end
  end

  defmodule Parser do
    @not_allowed {:error, :not_allowed}

    def is_allowed(map, uri) do
      path = %{uri | scheme: nil, authority: nil, host: nil, port: nil} |> URI.to_string()
      filtered = Map.merge(Map.get(map, "*", %{}), Map.get(map, "PandoraBot", %{}), fn _, v1, v2 -> Enum.dedup(v1 ++ v2) end)
      cond do
        map_size(filtered) == 0 -> :ok
        length(filtered.disallowed) == 0 -> :ok
        true -> do_match(filtered, path)
      end
    end

    # TODO: Match patterns better (support wildcards and $)
    defp do_match(%{allowed: allowed, disallowed: disallowed}, path) do
      case Enum.any?(disallowed, fn pattern ->
        if pattern == "" do
          @not_allowed
        else
          if String.starts_with?(path, pattern), do: :ok, else: @not_allowed
        end
      end) do
        true -> if Enum.any?(allowed, fn pattern -> String.starts_with?(path, pattern) end), do: :ok, else: @not_allowed
        false -> @not_allowed
      end
    end

    def parse(body) do
      body
      |> String.split("\n")
      |> Enum.map(&parse_line/1)
      |> Enum.reduce({:invalid, %{invalid: %{allowed: [], disllowed: []}}}, fn line, {curr, acc} ->
        case line do
          {:user_agent, agent} ->
            {agent, Map.put(acc, agent, %{allowed: [], disallowed: []})}
          {:allow, path} ->
            {curr, update_in(acc[curr][:allowed], fn curr_val -> [path | curr_val] end)}
          {:disallow, path} ->
            {curr, update_in(acc[curr][:disallowed], fn curr_val -> [path | curr_val] end)}
          _ -> {curr, acc}
        end
      end)
      |> elem(1)
      |> Map.delete(:invalid)
    end

    defp parse_line(line) do
      cond do
        String.starts_with?(line, "#") -> :ok
        res = Regex.run(~r/disallow: ?(.+)/i, line) -> {:disallow, Enum.at(res, 1)}
        res = Regex.run(~r/allow: ?(.+)/i, line) -> {:allow, Enum.at(res, 1)}
        res = Regex.run(~r/user-agent: ?(.+)/i, line) -> {:user_agent, Enum.at(res, 1)}
        true -> :ok
      end
    end
  end
end
