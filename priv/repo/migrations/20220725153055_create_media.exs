defmodule Caddishouse.Repo.Migrations.CreateMedia do
  use Ecto.Migration

  def change do
    create table(:media, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :size, :integer
      add :mimetype, :string
      add :source_key, :string
      add :last_viewed_at, :utc_datetime
      add :file, :string
      add :user_id, references(:users, on_delete: :nothing, type: :binary_id)
      add :oauth_user_id, references(:oauth_users, on_delete: :nothing, type: :binary_id)
      add :metadata, :map

      timestamps()
    end

    create index(:media, [:user_id])
    create unique_index(:media, [:source_key, :oauth_user_id])
  end
end
