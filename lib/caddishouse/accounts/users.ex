defmodule Caddishouse.Accounts.Users do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias Caddishouse.Repo

  alias Caddishouse.Accounts.{User, UserToken, OAuthUser}

  def get_by_id!(id), do: Repo.get!(User, id)
  def get_oauth_user_by_id!(id), do: Repo.get!(OAuthUser, id)

  def create_user() do
    User.build()
    |> Repo.insert()
  end

  def list_oauth_users(%User{} = user) do
    Repo.all(
      from(o in OAuthUser,
        where: ^user.id == o.user_id
      )
      |> OAuthUser.active()
    )
  end

  @doc """
  Gets the user with the given signed token.
  """
  def get_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  # TODO ecto has a get_or_create we could use...
  def get_or_create_by_email(email) do
    user =
      Repo.one(
        from u in User,
          distinct: true,
          inner_join: o in OAuthUser,
          where: o.email == ^email,
          limit: 1
      )

    if is_nil(user) do
      {:ok, user} = create_user()
      user
    else
      user
    end
  end

  def connected_to_provider?(%User{} = user, provider) do
    Repo.exists?(
      from(o in OAuthUser,
        where: ^user.id == o.user_id and o.provider == ^provider
      )
      |> OAuthUser.active()
    )
  end

  def revoke_oauth_user(%OAuthUser{} = oauth) do
    OAuthUser.revoke(oauth)
    |> Repo.update()
  end

  def update_access_token(%OAuthUser{} = oauth, access_token) when is_binary(access_token) do
    OAuthUser.update_access_token(oauth, access_token)
    |> Repo.update()
  end

  def create_or_update_oauth!(%User{} = user, provider, %Ueberauth.Auth{
        uid: uid,
        credentials: credentials,
        info: %{
          email: email
        }
      }) do
    access_token = credentials.token
    refresh_token = credentials.refresh_token

    OAuthUser.build(%{
      "email" => email,
      "refresh_token" => refresh_token,
      "access_token" => access_token,
      "provider" => String.to_existing_atom(provider),
      "external_id" => uid,
      "scopes" => credentials.scopes,
      "user_id" => user.id
    })
    |> Repo.insert!(
      on_conflict: [set: [access_token: access_token]],
      conflict_target: [:email, :provider]
    )
  end

  def broadcast_to(%User{} = user, :media_imported, media_id) do
    CaddishouseWeb.Endpoint.broadcast("user_socket:#{user.id}", "media_imported", media_id)
  end

  def broadcast_to(%User{} = user, :media_not_imported, media_name) do
    CaddishouseWeb.Endpoint.broadcast("user_socket:#{user.id}", "media_not_imported", media_name)
  end
end
