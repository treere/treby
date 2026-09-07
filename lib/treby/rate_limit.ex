defmodule Treby.RateLimit do
  @moduledoc """
  Request rate limiting backed by Hammer (ETS, single node).

  Centralizes bucket naming, configured thresholds, and the backend seam
  so controllers stay thin and tests can stub the backend via config.

  Config (`config :treby, :rate_limits`, keyword list, env-overridable):

      login_ip: {60_000, 5}          # 5 logins/min per IP
      login_email: {3_600_000, 10}   # 10 logins/hour per email
      otp_request_ip: {60_000, 5}    # 5 OTP requests/min per IP
      otp_request_email: {3_600_000, 5} # 5 OTP requests/hour per email
      otp_verify_ip: {60_000, 10}    # 10 OTP verifications/min per IP
  """

  @type verdict :: :allow | {:deny, retry_after_ms :: non_neg_integer()}

  @doc """
  Checks `key` against the named bucket. Returns `:allow` or
  `{:deny, retry_after_ms}`.
  """
  @spec check(atom(), String.t()) :: verdict()
  def check(bucket, key) when is_atom(bucket) and is_binary(key) do
    {scale_ms, limit} = bucket_config(bucket)

    backend().check_rate("#{bucket}:#{key}", scale_ms, limit)
    |> case do
      {:allow, _count} -> :allow
      {:deny, _limit} -> {:deny, scale_ms}
    end
  end

  @doc false
  def bucket_config(bucket) do
    configured = Application.get_env(:treby, :rate_limits, [])

    Keyword.get(configured, bucket, default_bucket(bucket))
  end

  defp default_bucket(:login_ip), do: {60_000, 5}
  defp default_bucket(:login_email), do: {3_600_000, 10}
  defp default_bucket(:otp_request_ip), do: {60_000, 5}
  defp default_bucket(:otp_request_email), do: {3_600_000, 5}
  defp default_bucket(:otp_verify_ip), do: {60_000, 10}
  defp default_bucket(_), do: {60_000, 5}

  defp backend do
    Application.get_env(:treby, :rate_limit_backend, Hammer)
  end
end
