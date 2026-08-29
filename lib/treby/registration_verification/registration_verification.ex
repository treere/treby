defmodule Treby.RegistrationVerification do
  @moduledoc """
  Verifies an email address before a company account is created, using a
  6-digit one-time code sent to the address.

  Only the SHA-256 hash of the code is stored in `registration_otps`.
  """

  import Ecto.Query, warn: false
  alias Treby.Repo
  alias Treby.RegistrationVerification.RegistrationOtp

  @otp_validity_minutes Application.compile_env(
                          :treby,
                          [Treby.RegistrationVerification, :otp_validity_minutes],
                          10
                        )
  @otp_resend_cooldown_seconds Application.compile_env(
                                 :treby,
                                 [Treby.RegistrationVerification, :otp_resend_cooldown_seconds],
                                 60
                               )

  @doc """
  Generates a one-time code for an email and returns the raw 6-digit code.
  Only the SHA-256 hash of the code is stored.

  Invalidates any previously pending code for the email. Returns
  `{:error, :rate_limited}` if a code was requested less than
  `otp_resend_cooldown_seconds` ago.
  """
  def generate_code(email) when is_binary(email) do
    now = DateTime.utc_now()

    case latest_pending_otp(email) do
      %{inserted_at: inserted_at} ->
        if DateTime.diff(now, inserted_at, :second) < @otp_resend_cooldown_seconds do
          {:error, :rate_limited}
        else
          do_generate_code(email, now)
        end

      nil ->
        do_generate_code(email, now)
    end
  end

  defp do_generate_code(email, now) do
    raw_code = (:rand.uniform(1_000_000) - 1) |> Integer.to_string() |> String.pad_leading(6, "0")
    hashed_code = hash_code(raw_code)

    expires_at = now |> DateTime.add(@otp_validity_minutes, :minute)

    Repo.transaction(fn ->
      invalidate_pending(email)

      %RegistrationOtp{}
      |> RegistrationOtp.changeset(%{
        email: email,
        code: hashed_code,
        expires_at: expires_at
      })
      |> Repo.insert()
    end)
    |> case do
      {:ok, {:ok, _}} -> {:ok, raw_code}
      {:ok, {:error, changeset}} -> {:error, changeset}
      {:error, _} -> {:error, :invalid}
    end
  end

  @doc """
  Verifies a submitted code for an email. Returns `:ok` on success and
  invalidates all pending codes for the email.
  """
  def verify_code(email, raw_code) when is_binary(email) and is_binary(raw_code) do
    now = DateTime.utc_now()
    hashed_code = hash_code(raw_code)

    RegistrationOtp
    |> where([o], o.email == ^email and o.code == ^hashed_code)
    |> Repo.one()
    |> case do
      nil ->
        {:error, :invalid_or_expired}

      %{used_at: used_at} when not is_nil(used_at) ->
        {:error, :invalid_or_expired}

      %{attempts: attempts} when attempts >= 5 ->
        {:error, :too_many_attempts}

      otp ->
        if DateTime.compare(otp.expires_at, now) == :lt do
          {:error, :invalid_or_expired}
        else
          Repo.transaction(fn ->
            otp
            |> RegistrationOtp.changeset(%{used_at: now})
            |> Repo.update!()

            invalidate_pending(email)
          end)
          |> case do
            {:ok, _} -> :ok
            {:error, _} -> {:error, :invalid}
          end
        end
    end
  end

  @doc """
  Registers a failed verification attempt for an email's pending code.
  """
  def record_failed_attempt(email) when is_binary(email) do
    case latest_pending_otp(email) do
      nil ->
        :ok

      otp ->
        otp
        |> RegistrationOtp.changeset(%{attempts: otp.attempts + 1})
        |> Repo.update()
        |> case do
          {:ok, _} -> :ok
          {:error, _} -> :ok
        end
    end
  end

  @doc """
  Marks all pending codes for an email as used.
  """
  def invalidate_pending(email) when is_binary(email) do
    RegistrationOtp
    |> where([o], o.email == ^email and is_nil(o.used_at))
    |> Repo.update_all(set: [used_at: DateTime.utc_now()])
  end

  @doc """
  Deletes registration OTPs older than the given age (default 24 hours).
  """
  def delete_expired(age \\ {24, :hour}) do
    cutoff =
      DateTime.utc_now()
      |> DateTime.truncate(:second)
      |> DateTime.add(-elem(age, 0), elem(age, 1))

    RegistrationOtp
    |> where([o], o.inserted_at < ^cutoff)
    |> Repo.delete_all()
  end

  defp latest_pending_otp(email) do
    RegistrationOtp
    |> where([o], o.email == ^email and is_nil(o.used_at))
    |> order_by([o], desc: o.inserted_at)
    |> limit(1)
    |> Repo.one()
  end

  defp hash_code(raw_code) do
    :crypto.hash(:sha256, raw_code) |> Base.url_encode64(padding: false)
  end
end
