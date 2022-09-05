defmodule Caddishouse.Repo.Migrations.CreateOauthUsers do
  use Ecto.Migration

  def change do
    create table(:oauth_users, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :scopes, {:array, :string}
      add :provider, :integer
      add :external_id, :string
      add :access_token, :string
      add :refresh_token, :string
      add :user_id, references(:users, on_delete: :nothing, type: :binary_id)

      timestamps()
    end

    create unique_index(:oauth_users, [:user_id, :provider])
  end
end
