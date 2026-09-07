defmodule Treby.UploadsTest do
  use Treby.DataCase, async: true

  describe "get_presigned_url/3" do
    test "returns a presigned URL string" do
      key = "test/some-file.pdf"
      assert {:ok, url} = Treby.Uploads.get_presigned_url("test", key)
      assert is_binary(url)
      assert String.contains?(url, "X-Amz")
    end

    test "supports custom expiry" do
      key = "test/some-file.pdf"
      assert {:ok, url} = Treby.Uploads.get_presigned_url("test", key, expires_in: 600)
      assert is_binary(url)
      assert String.contains?(url, "X-Amz")
    end

    test "rejects non-tenant keys without any S3 request" do
      assert_raise ArgumentError, fn ->
        Treby.Uploads.get_presigned_url("test", "other-tenant/some-file.pdf")
      end

      assert_raise ArgumentError, fn ->
        Treby.Uploads.delete_file("test", "other-tenant/some-file.pdf")
      end
    end
  end

  describe "bucket/0" do
    test "defaults to treby-uploads" do
      Application.delete_env(:treby, :s3_bucket)
      Application.put_env(:treby, :s3_bucket, "treby-uploads")
      assert Treby.Uploads.bucket() == "treby-uploads"
    end

    test "reflects runtime override" do
      Application.put_env(:treby, :s3_bucket, "custom-bucket")
      assert Treby.Uploads.bucket() == "custom-bucket"
      Application.put_env(:treby, :s3_bucket, "treby-uploads")
    end
  end

  describe "scoped_key/2" do
    test "returns key when prefixed with tenant id" do
      assert Treby.Uploads.scoped_key("tenant-1", "tenant-1/resumes/a.pdf") ==
               "tenant-1/resumes/a.pdf"
    end

    test "raises on cross-tenant key" do
      assert_raise ArgumentError, fn ->
        Treby.Uploads.scoped_key("tenant-1", "other-tenant/resumes/a.pdf")
      end
    end
  end
end
