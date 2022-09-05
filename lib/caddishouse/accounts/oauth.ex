defmodule Caddishouse.Accounts.OAuthUser do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Query, warn: false
  import Ecto.Changeset

  @providers [
               # Drive
               :google,
               # Onedrive
               :microsoft
             ]
             |> Enum.with_index()

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "oauth_users" do
    field :email, :string
    field :access_token, :string
    field :refresh_token, :string
    field :scopes, {:array, :string}
    field :revoked_at, :utc_datetime

    field :external_id, :string
    field :provider, Ecto.Enum, values: @providers
    belongs_to :user, Caddishouse.Accounts.User

    timestamps()
  end

  def providers(), do: @providers

  @doc false
  def build(attrs) do
    %__MODULE__{}
    |> cast(attrs, [
      :email,
      :external_id,
      :user_id,
      :scopes,
      :provider,
      :access_token,
      :refresh_token,
      :revoked_at
    ])
    |> validate_required([
      :email,
      :external_id,
      :user_id,
      :scopes,
      :provider,
      :access_token
    ])
    |> unique_constraint([:email, :provider])
  end

  @doc false
  def update_access_token(%__MODULE__{} = oauth_user, access_token) do
    oauth_user
    |> change(access_token: access_token)
    |> then(fn oauth_user ->
      if is_nil(access_token) do
        revoke(oauth_user)
      else
        change(oauth_user, revoked_at: nil)
      end
    end)
  end

  @doc false
  def revoke(oauth_user) do
    oauth_user
    |> change(revoked_at: Timex.now())
  end

  def active(query), do: query |> where([o], is_nil(o.revoked_at))
end
