defmodule Treby.RegistrationOtpEmail do
  @moduledoc """
  Email template for the registration email verification code.
  """

  import Swoosh.Email

  def otp_email(email, code) do
    new()
    |> to(email)
    |> from({"Treby", "noreply@treby.app"})
    |> subject("Verify your email address")
    |> html_body("""
    <h2>Verify your email address</h2>
    <p>Hi,</p>
    <p>Use the code below to verify your email and complete your Treby account:</p>
    <p style="font-size: 32px; font-weight: bold; letter-spacing: 8px; color: #2563eb;">#{code}</p>
    <p>This code expires in 10 minutes.</p>
    <p><a href="/register/verify" style="display: inline-block; padding: 12px 24px; background-color: #2563eb; color: white; text-decoration: none; border-radius: 6px;">Enter your code</a></p>
    <p>If you didn't request this, you can safely ignore this email.</p>
    """)
    |> text_body("""
    Verify your email address

    Hi,

    Use the code below to verify your email and complete your Treby account:

    #{code}

    This code expires in 10 minutes.

    Enter it here: /register/verify

    If you didn't request this, you can safely ignore this email.
    """)
  end
end
