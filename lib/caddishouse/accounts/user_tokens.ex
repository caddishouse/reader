defmodule Caddishouse.Accounts.UserTokens do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias Caddishouse.Repo

  alias Caddishouse.Accounts.UserToken

  @doc """
  Generates a session token.
  """
  def generate(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete(token) do
    Repo.delete_all(UserToken.token_and_context_query(token, "session"))
    :ok
  end
end
