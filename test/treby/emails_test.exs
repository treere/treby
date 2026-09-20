defmodule Treby.EmailsTest do
  use ExUnit.Case, async: true

  alias Treby.Emails

  test "accepts well-formed addresses" do
    for email <- ["a@b.com", "first.last@sub.example.co", "x+tag@example.io"] do
      assert Emails.valid?(email), "expected #{email} to be valid"
    end
  end

  test "rejects malformed addresses" do
    for email <- ["a@b", "not-an-email", "a@", "@b.com", "a b@c.com", "a@b.", ""] do
      refute Emails.valid?(email), "expected #{inspect(email)} to be invalid"
    end
  end

  test "non-binary values are invalid" do
    refute Emails.valid?(nil)
    refute Emails.valid?(:a)
  end

  test "validate_format adds the shared error message" do
    changeset =
      {%{}, %{email: :string}}
      |> Ecto.Changeset.cast(%{email: "a@b"}, [:email])
      |> Emails.validate_format(:email)

    assert {"must be a valid email address", _} = changeset.errors[:email]
  end
end
