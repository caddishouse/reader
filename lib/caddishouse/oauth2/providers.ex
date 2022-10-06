defmodule Caddishouse.OAuth2.Providers do
  @moduledoc false
  alias Caddishouse.Accounts.{User, OAuthUser}
  require Logger

  @pdf_mimetype "application/pdf"
  defp google_api, do: Application.get_env(:caddishouse, :google_api, Caddishouse.OAuth2.Google)

  def search(%User{} = user, %OAuthUser{provider: :google} = oauth_user, query) do
    _search(google_api(), user, oauth_user, query)
  end

  def download(
        %User{} = user,
        %OAuthUser{provider: :google} = oauth_user,
        file_id,
        file_destination
      ) do
    _download(google_api(), user, oauth_user, file_id, file_destination)
  end

  defp _search(api, %User{} = user, %OAuthUser{} = oauth_user, query, retries \\ 1) do
    connection = api.connect(oauth_user.access_token)
    request = api.list_files(connection, query, types: [@pdf_mimetype])

    case request do
      {:ok, files} ->
        {:ok, files}

      {:error, :bad_token} = error ->
        if retries > 0 do
          case api.refresh_token(oauth_user) do
            {:ok, :oauth_user_revoked} ->
              {:error, :oauth_user_revoked}

            {:ok, %OAuthUser{} = updated_oauth} ->
              _search(api, user, updated_oauth, query, retries - 1)

            error ->
              error
          end
        else
          error
        end

      {:error, error} ->
        Logger.error("""
        Could not search cloud storage for user #{user.id} using #{oauth_user.id}
        #{inspect(error)}
        """)

        {:error, error}
    end
  end

  defp _download(
         api,
         %User{} = user,
         %OAuthUser{} = oauth_user,
         file_id,
         file_destination
       ) do
    connection = api.connect(oauth_user.access_token)
    request = api.get_file(connection, file_id, file_destination)

    case request do
      {:ok, file_path} ->
        {:ok, file_path}

      {:error, error} ->
        Logger.error("""
          Google download failed for user #{user.id}
          #{inspect(error)}
        """)

        {:error, error}
    end
  end
end
