defmodule Treby.PasswordResetEmail do
  @moduledoc """
  Email templates for password reset.
  """

  import Swoosh.Email

  def reset_email(user, reset_url) do
    new()
    |> to(user.email)
    |> from({"Treby", "noreply@treby.app"})
    |> subject("Reset your password on Treby")
    |> html_body("""
    <h2>Reset your password</h2>
    <p>Hi #{user.name},</p>
    <p>We received a request to reset your password. Click the link below to choose a new password:</p>
    <p><a href="#{reset_url}">Reset Password</a></p>
    <p>This link expires in 1 hour and can only be used once.</p>
    <p>If you didn't request this, you can safely ignore this email.</p>
    """)
    |> text_body("""
    Reset your password

    Hi #{user.name},

    We received a request to reset your password. Click the link below to choose a new password:

    #{reset_url}

    This link expires in 1 hour and can only be used once.

    If you didn't request this, you can safely ignore this email.
    """)
  end
end
