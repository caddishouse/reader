defmodule Caddishouse.Documents.Jobs.ImportMedia do
  @moduledoc false
  # 1 day
  use Oban.Worker, queue: :import_media, max_attempts: 2, unique: [period: 60 * 60 * 24]

  alias Caddishouse.Documents
  alias Caddishouse.OAuth2.Providers
  alias Caddishouse.Accounts.Users

  @impl Oban.Worker
  def perform(%Oban.Job{
        args:
          %{
            "user_id" => user_id,
            "oauth_user_id" => oauth_user_id,
            "source_key" => source_key,
            "file_name" => file_name
          } = _args
      }) do
    user = Users.get_by_id!(user_id)

    oauth_user = Users.get_oauth_user_by_id!(oauth_user_id)

    case Providers.download(user, oauth_user, source_key, fn ->
           {"/tmp/#{source_key}", File.stream!("/tmp/#{source_key}", [])}
         end) do
      {:ok, file_path} ->
        process_download(user, oauth_user, file_path, file_name, source_key)

      {:error, error} ->
        Users.broadcast_to(user, :media_not_imported, file_name)
        {:error, error}
    end
  end

  defp process_download(user, oauth_user, file_path, file_name, source_key) do
    %{size: file_size} = File.stat!(file_path)

    file_ext = Path.extname(file_path) |> String.trim_leading(".")

    Documents.find_or_create(%{
      "name" => file_name,
      "file_size" => file_size,
      # TODO use a better method for finding correct mimetype
      "mimetype" => "application/#{file_ext}",
      "file" => %Plug.Upload{
        # Content type is needed, otherwise the file will be saved in the filesystem
        # with two extensions, e.g. "file-name.pdf.pdf"
        content_type: "application/#{file_ext}",
        filename: file_name,
        path: file_path
      },
      "user_id" => user.id,
      "oauth_user_id" => oauth_user.id,
      "source_key" => source_key
    })
    |> case do
      {:ok, media} ->
        Users.broadcast_to(user, :media_imported, media.id)
        :ok

      {:error, error} ->
        Users.broadcast_to(user, :media_not_imported, file_name)
        {:error, error}
    end
  end
end
