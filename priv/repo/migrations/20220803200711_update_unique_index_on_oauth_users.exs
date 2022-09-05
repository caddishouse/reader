defmodule Caddishouse.Repo.Migrations.UpdateUniqueIndexOnOauthUsers do
  use Ecto.Migration

  def change do
    drop unique_index(:oauth_users, [:user_id, :provider])
    create unique_index(:oauth_users, [:email, :provider])
  end
end
