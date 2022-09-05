defmodule Caddishouse.Accounts.User do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset
  alias Caddishouse.Accounts.OAuthUser

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "users" do
    has_many :providers, OAuthUser

    timestamps()
  end

  @doc false
  def build() do
    %__MODULE__{}
    |> cast(%{}, [])
  end
end
