defmodule Treby.RegistrationVerificationTest do
  use Treby.DataCase, async: true

  import Ecto.Query

  alias Treby.Repo
  alias Treby.RegistrationVerification
  alias Treby.RegistrationVerification.RegistrationOtp

  defp unique_email do
    "verify-#{System.unique_integer([:positive])}@example.com"
  end

  describe "generate_code/1" do
    test "creates a 6-digit code and stores only the hash" do
      email = unique_email()

      assert {:ok, code} = RegistrationVerification.generate_code(email)
      assert String.length(code) == 6
      assert code =~ ~r/^\d{6}$/

      otp = Repo.one(from o in RegistrationOtp, where: o.email == ^email)
      assert otp.code != code
    end

    test "rate limits within cooldown" do
      email = unique_email()

      assert {:ok, _} = RegistrationVerification.generate_code(email)
      assert {:error, :rate_limited} = RegistrationVerification.generate_code(email)
    end

    test "invalidates previous pending codes on resend" do
      email = unique_email()
      assert {:ok, _} = RegistrationVerification.generate_code(email)

      old_inserted = ~U[2020-01-01 00:00:00Z]

      Repo.update_all(
        from(o in RegistrationOtp,
          where: o.email == ^email,
          update: [set: [inserted_at: ^old_inserted]]
        ),
        []
      )

      assert {:ok, _} = RegistrationVerification.generate_code(email)

      otps = Repo.all(from o in RegistrationOtp, where: o.email == ^email)
      assert length(Enum.filter(otps, &is_nil(&1.used_at))) == 1
    end
  end

  describe "verify_code/2" do
    test "verifies a valid code and invalidates pending codes" do
      email = unique_email()
      {:ok, code} = RegistrationVerification.generate_code(email)

      assert :ok = RegistrationVerification.verify_code(email, code)

      otps = Repo.all(from o in RegistrationOtp, where: o.email == ^email)
      assert Enum.all?(otps, &(not is_nil(&1.used_at)))
    end

    test "returns error for invalid code" do
      email = unique_email()
      {:ok, _} = RegistrationVerification.generate_code(email)

      assert {:error, :invalid_or_expired} = RegistrationVerification.verify_code(email, "000000")
    end

    test "returns error after too many attempts" do
      email = unique_email()
      {:ok, code} = RegistrationVerification.generate_code(email)

      for _ <- 1..5 do
        RegistrationVerification.verify_code(email, "000000")
        RegistrationVerification.record_failed_attempt(email)
      end

      assert {:error, :too_many_attempts} = RegistrationVerification.verify_code(email, code)
    end

    test "returns error for expired code" do
      email = unique_email()
      {:ok, code} = RegistrationVerification.generate_code(email)

      Repo.update_all(
        from(o in RegistrationOtp,
          where: o.email == ^email,
          update: [set: [expires_at: ^~U[2020-01-01 00:00:00Z]]]
        ),
        []
      )

      assert {:error, :invalid_or_expired} = RegistrationVerification.verify_code(email, code)
    end
  end

  describe "record_failed_attempt/2" do
    test "increments the attempt count" do
      email = unique_email()
      {:ok, _} = RegistrationVerification.generate_code(email)

      assert :ok = RegistrationVerification.record_failed_attempt(email)

      otp = Repo.one(from o in RegistrationOtp, where: o.email == ^email)
      assert otp.attempts == 1
    end
  end
end
