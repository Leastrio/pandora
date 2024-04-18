defmodule Pandora.Schema.Entry do
  use Ecto.Schema
  import Ecto.Query, only: [from: 2]

  schema "entry" do
    field :url, :string
    timestamps type: :utc_datetime
  end

  def get_all_matches(urls) do
    Pandora.Repo.all(from e in __MODULE__, where: e.url in ^urls, select: e.url)
  end
end
