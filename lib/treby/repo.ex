defmodule Treby.Repo do
  use Ecto.Repo,
    otp_app: :treby,
    adapter: Ecto.Adapters.Postgres
end
