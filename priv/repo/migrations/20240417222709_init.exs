defmodule Pandora.Repo.Migrations.Init do
  use Ecto.Migration

  def change do
    create table(:entry) do
      add :url, :string
      timestamps(type: :utc_datetime)
    end

    create table(:invalid) do
      add :url, :string
      timestamps(type: :utc_datetime)
    end
  end
end
