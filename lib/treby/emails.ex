defmodule Treby.Emails do
  @moduledoc """
  Single source of truth for email shape validation across the application.

  Every email field (candidates, invites, users, registration) validates the
  same way: a non-empty local part, a domain with at least one dot, and no
  whitespace. Deliverability is what matters, so `a@b` is not accepted.
  """

  import Ecto.Changeset, only: [validate_format: 4]

  @regex ~r/^[^\s@]+@[^\s@]+\.[^\s@]+$/
  @message "must be a valid email address"

  @doc """
  Returns true when the string looks like a deliverable email address.
  """
  def valid?(email) when is_binary(email), do: Regex.match?(@regex, email)
  def valid?(_), do: false

  @doc """
  Adds a format error to `field` when it is not a valid email address.
  """
  def validate_format(changeset, field) do
    validate_format(changeset, field, @regex, message: @message)
  end
end
