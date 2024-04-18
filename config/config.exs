import Config

config :pandora,
  ecto_repos: [Pandora.Repo]

config :pandora, Pandora.Repo,
  database: "pandora",
  username: "pandora",
  password: "password",
  hostname: "localhost"
