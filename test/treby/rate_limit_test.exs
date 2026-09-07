defmodule Treby.RateLimitTest do
  use ExUnit.Case, async: true

  alias Treby.RateLimit

  test "allows up to the limit then denies with retry hint" do
    # Unknown bucket falls back to {60_000, 5}; unique key per test.
    key = "unit-#{System.unique_integer([:positive])}"

    for _ <- 1..5 do
      assert :allow = RateLimit.check(:rate_limit_unit_test_bucket, key)
    end

    assert {:deny, 60_000} = RateLimit.check(:rate_limit_unit_test_bucket, key)
  end

  test "bucket_config/1 resolves configured buckets and defaults" do
    assert {scale_ms, limit} = RateLimit.bucket_config(:login_ip)
    assert is_integer(scale_ms) and scale_ms > 0
    assert is_integer(limit) and limit > 0
    assert {60_000, 5} = RateLimit.bucket_config(:no_such_bucket_xyz)
  end
end
