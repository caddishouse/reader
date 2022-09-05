defmodule Caddishouse.Repo.Migrations.AddIsRevokedToOauth do
  use Ecto.Migration

  def change do
    alter table("oauth_users") do
      add :revoked_at, :utc_datetime
    end
  end
end
