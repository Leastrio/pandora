defmodule Pandora.Processor do
  require Logger

  @headers [
    user_agent:
      "PandoraBot/#{Mix.Project.config()[:version]} (https://github.com/Leastrio/pandora)"
  ]

  @schemes ["https", "http", nil]

  # TODO: respect robots.txt
  def process(msg) do
    url = parse_parent_url(msg.data)
    url_s = URI.to_string(url)

    if Pandora.Cache.insert_new(url_s) do
      Logger.debug("Processing #{msg.data}")

      with {:ok, %{body: body}} <- Req.get(url_s, headers: @headers),
           {:ok, links} <- parse_body(body),
           parsed_links <- parse_links(url, links) do
        {:ok, {url_s, parsed_links}}
      else
        {:error, :invalid_doc} -> {:error, "Body is not a valid HTML document"}
        {:error, _} -> {:error, "Error while sending GET request to URL"}
      end
    else
      :noop
    end
  end

  defp parse_body(body) do
    case Floki.parse_document(body) do
      {:ok, doc} ->
        {:ok, Floki.attribute(doc, "a", "href")}

      _ ->
        {:error, :invalid_doc}
    end
  end

  defp parse_links(parent, links) do
    Enum.flat_map(links, fn link ->
      case URI.new(link) do
        {:ok, uri} -> parse_uri(uri, parent)
        {:error, _} -> []
      end
    end)
  end

  defp parse_uri(uri, _parent) do
    if uri.scheme in @schemes do
      if uri.scheme == nil do
        # TODO: fix short urls (ex. turn "/help" to "google.com/help")
        []
      else
        [URI.to_string(uri)]
      end
    else
      []
    end
  end

  defp parse_parent_url(url) do
    url = URI.parse(url)

    cond do
      url.path == nil -> url
      url.path == "/" -> %{url | path: nil}
      String.ends_with?(url.path, "/") -> %{url | path: String.trim_trailing(url.path, "/")}
      true -> url
    end
  end
end
