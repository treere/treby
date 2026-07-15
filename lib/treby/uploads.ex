defmodule Treby.Uploads do
  @moduledoc """
  S3 client wrapper for file uploads (resumes, logos).
  Uses ExAWS with S3 adapter (MinIO in dev, S3 in prod).
  """

  @bucket "treby-uploads"

  def upload_file(key, file_content, content_type \\ "application/octet-stream") do
    @bucket
    |> ExAws.S3.put_object(key, file_content, content_type: content_type)
    |> ExAws.request()
  end

  def get_presigned_url(key, opts \\ []) do
    expires_in = Keyword.get(opts, :expires_in, 3600)
    config = ExAws.Config.new(:s3)

    ExAws.S3.presigned_url(config, :get, @bucket, key, expires_in: expires_in)
  end

  def delete_file(key) do
    @bucket
    |> ExAws.S3.delete_object(key)
    |> ExAws.request()
  end

  def ensure_bucket_exists! do
    case ExAws.S3.head_bucket(@bucket) |> ExAws.request() do
      {:ok, _} -> :ok
      {:error, _} -> ExAws.S3.put_bucket(@bucket, "us-east-1") |> ExAws.request()
    end
  end
end
