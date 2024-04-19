defmodule Pandora.Repo.Migrations.Init do
  use Ecto.Migration

  def change do
    create table(:entry, primary_key: false) do
      add :url, :text, primary_key: true
      timestamps(type: :utc_datetime)
    end

    create table(:invalid, primary_key: false) do
      add :url, :text, primary_key: true
      timestamps(type: :utc_datetime)
    end
  end
end
