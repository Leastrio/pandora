defmodule Pandora.Schema.Entry do
  use Ecto.Schema
  import Ecto.Query, only: [from: 2]

  @primary_key false
  schema "entry" do
    field(:url, :string, primary_key: true)
    timestamps(type: :utc_datetime)
  end

  def get_all() do
    Pandora.Repo.all(from(e in __MODULE__, select: e.url))
  end
end
