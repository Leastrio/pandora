defmodule Pandora.Schema.Invalid do
  use Ecto.Schema

  schema "invalid" do
    field :url, :string
    timestamps type: :utc_datetime
  end
end
