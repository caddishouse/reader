defmodule Caddishouse.Repo.Migrations.AddSizeAndMimetypeToMedia do
  use Ecto.Migration

  def change do
    alter table(:media) do
      add :file_size, :integer
    end
  end
end
