defmodule Treby.Test.RateLimitNoInspectBackend do
  @moduledoc false
  def check_rate(_id, _scale_ms, _limit), do: {:deny, 1}
end

defmodule Treby.RateLimitTest do
  use ExUnit.Case, async: true

  alias Treby.RateLimit

  test "allows up to the limit then denies with retry hint" do
    # Unknown bucket falls back to {60_000, 5}; unique key per test.
    key = "unit-#{System.unique_integer([:positive])}"

    for _ <- 1..5 do
      assert :allow = RateLimit.check(:rate_limit_unit_test_bucket, key)
    end

    assert {:deny, ms} = RateLimit.check(:rate_limit_unit_test_bucket, key)
    assert is_integer(ms) and ms > 0 and ms <= 60_000
  end

  test "denies with the bucket window when the backend has no inspect_bucket" do
    previous = Application.get_env(:treby, :rate_limit_backend, Hammer)
    Application.put_env(:treby, :rate_limit_backend, Treby.Test.RateLimitNoInspectBackend)
    on_exit(fn -> Application.put_env(:treby, :rate_limit_backend, previous) end)

    assert {:deny, 60_000} =
             RateLimit.check(
               :rate_limit_unit_test_bucket,
               "window-#{System.unique_integer([:positive])}"
             )
  end

  test "bucket_config/1 resolves configured buckets and defaults" do
    assert {scale_ms, limit} = RateLimit.bucket_config(:login_ip)
    assert is_integer(scale_ms) and scale_ms > 0
    assert is_integer(limit) and limit > 0
    assert {60_000, 5} = RateLimit.bucket_config(:no_such_bucket_xyz)
  end
end
