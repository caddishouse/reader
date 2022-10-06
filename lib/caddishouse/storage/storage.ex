defmodule Caddishouse.Storage do
  @moduledoc false
  alias Caddishouse.Documents.Media

  @type media_t :: map()
  @callback get_url(String.t(), String.t()) :: {:ok, String.t()} | {:error, any()}
  @callback delete(String.t(), String.t()) ::
              {:ok, any()} | {:error, any()}

  defp storage_api(), do: Application.get_env(:caddishouse, :storage_api, Caddishouse.Storage.S3)

  def delete(%Media{} = media) do
    storage_api().delete("uploads", "/user/#{media.user_id}/media/#{media.id}/#{media.name}")
  end

  def get_url(%Media{} = media) do
    storage_api().get_url("uploads", "/user/#{media.user_id}/media/#{media.id}/#{media.name}")
  end
end
