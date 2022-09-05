defmodule Caddishouse.OAuth2.Google do
  @moduledoc false

  @behaviour Caddishouse.OAuth2.Provider

  alias Caddishouse.Accounts.{OAuthUser, Users}
  require Logger

  @impl true
  def connect(token) do
    GoogleApi.Drive.V3.Connection.new(token)
  end

  @impl true
  def list_files(connection, query, opts \\ []) do
    file_types = Keyword.get(opts, :types, [])

    types =
      Enum.map(file_types, &" and mimeType = '#{&1}'")
      |> Enum.join("")

    case GoogleApi.Drive.V3.Api.Files.drive_files_list(connection,
           q: "name contains '#{query}' #{types}",
           includeItemsFromAllDrives: true,
           supportsAllDrives: true,
           corpora: "allDrives",
           fields:
             "files/thumbnailLink,files/mimeType,files/id,files/name,files/webContentLink,files/webViewLink"
         ) do
      {:ok, %GoogleApi.Drive.V3.Model.FileList{files: file_list}} ->
        {:ok, Enum.map(file_list, &parse_list_results/1)}

      {:error, %Tesla.Env{status: 401} = _error} ->
        {:error, :bad_token}

      error ->
        error
    end
  end

  @impl true
  def get_file(connection, file_id, file_destination) do
    middleware = Tesla.Client.middleware(connection)

    connection =
      Tesla.client(middleware, {Tesla.Adapter.Mint, [body_as: :stream, timeout: 30_000]})

    request =
      GoogleApi.Drive.V3.Api.Files.drive_files_get(
        connection,
        file_id,
        acknowledgeAbuse: true,
        alt: "media"
      )

    case request do
      {:ok, %Tesla.Env{body: body}} ->
        {file_path, file_stream} = file_destination.()

        body
        |> Stream.into(file_stream)
        |> Stream.run()

        {:ok, file_path}

      error ->
        error
    end
  end

  @impl true
  # TODO part of this should be moved to providers
  def refresh_token(%OAuthUser{provider: :google} = oauth_user) do
    result =
      Ueberauth.Strategy.Google.OAuth.client(
        strategy: OAuth2.Strategy.Refresh,
        params: %{"refresh_token" => oauth_user.refresh_token}
      )
      |> OAuth2.Client.get_token()

    case result do
      {:ok, %OAuth2.Client{token: %OAuth2.AccessToken{access_token: access_token}}} ->
        Users.update_access_token(oauth_user, access_token)

      {:error, %OAuth2.Response{body: %{"error" => "invalid_grant"}}} ->
        case Users.revoke_oauth_user(oauth_user) do
          {:ok, _} -> {:ok, :oauth_user_revoked}
          error -> error
        end

      error ->
        Logger.error("""
          Unable to refresh user's token, oauth_user_id: #{oauth_user.id}.
          #{inspect(error)}
        """)

        error
    end
  end

  defp parse_list_results(%GoogleApi.Drive.V3.Model.File{} = file) do
    Map.take(file, [:id, :name, :webContentLink])
    |> Map.put(:source, :google)
  end
end
