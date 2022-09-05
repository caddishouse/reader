defmodule Caddishouse.Repo.Migrations.RemoveEmailFromUsersAndAddToOauth do
  use Ecto.Migration

  def change do
    alter table("oauth_users") do
      add :email, :string
    end

    alter table("users") do
      remove :email
    end
  end
end
