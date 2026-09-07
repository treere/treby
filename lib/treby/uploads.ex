defmodule Treby.Uploads do
  @moduledoc """
  S3 client wrapper for file uploads (resumes, logos).
  Uses ExAWS with S3 adapter (RustFS in dev, S3 in prod).

  The bucket is runtime-configurable via `config :treby, :s3_bucket`
  (env `S3_BUCKET`, fallback `TREBY_S3_BUCKET`, default `"treby-uploads"`).

  All object operations take the tenant id and fail closed via `scoped_key/2`:
  keys not prefixed with `"tenant_id/"` raise `ArgumentError` before any
  S3 request is made.
  """

  @default_bucket "treby-uploads"

  @doc """
  Returns the configured S3 bucket.
  """
  @spec bucket() :: String.t()
  def bucket do
    Application.get_env(:treby, :s3_bucket, @default_bucket)
  end

  @doc """
  Validates that `key` is tenant-scoped (prefixed with the tenant id).

  Returns the key unchanged when valid, raises `ArgumentError` otherwise.
  """
  @spec scoped_key(String.t(), String.t()) :: String.t()
  def scoped_key(tenant_id, key) when is_binary(tenant_id) and is_binary(key) do
    prefix = "#{tenant_id}/"

    if String.starts_with?(key, prefix) do
      key
    else
      raise ArgumentError, "S3 key must be prefixed with #{inspect(prefix)}"
    end
  end

  def upload_file(tenant_id, key, file_content, content_type \\ "application/octet-stream") do
    tenant_id
    |> scoped_key(key)
    |> then(fn scoped ->
      bucket()
      |> ExAws.S3.put_object(scoped, file_content, content_type: content_type)
      |> ExAws.request(http_opts: [receive_timeout: 10_000])
    end)
  end

  def get_presigned_url(tenant_id, key, opts \\ []) do
    scoped = scoped_key(tenant_id, key)
    expires_in = Keyword.get(opts, :expires_in, 3600)
    config = ExAws.Config.new(:s3)

    ExAws.S3.presigned_url(config, :get, bucket(), scoped, expires_in: expires_in)
  end

  def delete_file(tenant_id, key) do
    tenant_id
    |> scoped_key(key)
    |> then(fn scoped ->
      bucket()
      |> ExAws.S3.delete_object(scoped)
      |> ExAws.request(http_opts: [receive_timeout: 5_000])
    end)
  end

  def ensure_bucket_exists! do
    bucket_name = bucket()

    case ExAws.S3.head_bucket(bucket_name)
         |> ExAws.request(http_opts: [receive_timeout: 5_000]) do
      {:ok, _} ->
        :ok

      {:error, _} ->
        ExAws.S3.put_bucket(bucket_name, "us-east-1")
        |> ExAws.request(http_opts: [receive_timeout: 5_000])
    end
  end
end
