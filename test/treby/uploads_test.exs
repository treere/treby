defmodule Treby.UploadsTest do
  use Treby.DataCase, async: true

  describe "get_presigned_url/2" do
    test "returns a presigned URL string" do
      key = "test/some-file.pdf"
      assert {:ok, url} = Treby.Uploads.get_presigned_url(key)
      assert is_binary(url)
      assert String.contains?(url, "X-Amz")
    end

    test "supports custom expiry" do
      key = "test/some-file.pdf"
      assert {:ok, url} = Treby.Uploads.get_presigned_url(key, expires_in: 600)
      assert is_binary(url)
      assert String.contains?(url, "X-Amz")
    end
  end
end
