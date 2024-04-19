defmodule Pandora.Schema.Invalid do
  use Ecto.Schema
  import Ecto.Query, only: [from: 2]

  @primary_key false
  schema "invalid" do
    field(:url, :string, primary_key: true)
    timestamps(type: :utc_datetime)
  end

  def get_all() do
    Pandora.Repo.all(from(i in __MODULE__, select: i.url))
  end
end
