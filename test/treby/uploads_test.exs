defmodule Treby.UploadsTest do
  use Treby.DataCase, async: true

  describe "get_presigned_url/2" do
    @tag :skip
    test "returns a presigned URL string" do
      key = "test/some-file.pdf"
      url = Treby.Uploads.get_presigned_url(key)
      assert is_binary(url)
      assert String.contains?(url, "X-Amz")
    end

    @tag :skip
    test "supports custom expiry" do
      key = "test/some-file.pdf"
      url = Treby.Uploads.get_presigned_url(key, expires_in: 600)
      assert is_binary(url)
      assert String.contains?(url, "X-Amz")
    end
  end
end
