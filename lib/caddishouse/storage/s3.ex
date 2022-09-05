defmodule Caddishouse.Storage.S3 do
  @moduledoc false

  @behaviour Caddishouse.Storage

  require Logger

  @impl true
  def get_url(bucket, object) do
    ExAws.Config.new(:s3)
    |> ExAws.S3.presigned_url(
      :get,
      bucket,
      object
    )
  end

  @impl true
  def delete(bucket, object) do
    ExAws.S3.delete_object(
      bucket,
      object
    )
    |> ExAws.request()
  end

  def put(file, bucket, object) do
    file
    |> ExAws.S3.upload(bucket, object)
    |> ExAws.request()
  end
end
