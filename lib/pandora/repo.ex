defmodule Pandora.Repo do
  use Ecto.Repo,
    otp_app: :pandora,
    adapter: Ecto.Adapters.Postgres
end
