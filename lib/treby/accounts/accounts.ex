defmodule Treby.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias Treby.Repo
  alias Treby.Accounts.User
  alias Treby.Accounts.PasswordResetToken

  def list_users(tenant_id) do
    User
    |> where([u], u.tenant_id == ^tenant_id)
    |> Repo.all()
  end

  def get_user!(id), do: Repo.get!(User, id)

  def get_user_by_email(email), do: Repo.get_by(User, email: email)

  def email_registered?(email) when is_binary(email) do
    Repo.exists?(from(u in User, where: u.email == ^email))
  end

  def email_registered?(_email), do: false

  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  def update_user(%User{} = user, attrs, actor \\ nil) do
    cond do
      actor && actor.id == user.id && Map.has_key?(attrs, "role") && attrs["role"] != "admin" ->
        {:error, :cannot_demote_self}

      actor && actor.role != "admin" && Map.has_key?(attrs, "role") ->
        {:error, :unauthorized}

      true ->
        user
        |> User.changeset(attrs)
        |> Repo.update()
    end
  end

  def update_locale(%User{} = user, locale) do
    user
    |> User.locale_changeset(%{locale: locale})
    |> Repo.update()
  end

  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  def remove_user_from_tenant(%User{} = user, actor \\ nil) do
    if actor && actor.role != "admin" do
      {:error, :unauthorized}
    else
      Repo.delete(user)
    end
  end

  def change_user(%User{} = user, attrs \\ %{}) do
    User.changeset(user, attrs)
  end

  def authenticate_user(email, password) do
    user = get_user_by_email(email)

    case user do
      nil ->
        Bcrypt.no_user_verify()
        {:error, :invalid_credentials}

      user ->
        if Bcrypt.verify_pass(password, user.password_hash) do
          {:ok, user}
        else
          {:error, :invalid_credentials}
        end
    end
  end

  @doc """
  Generates a password reset token for the given user.
  Returns {:ok, raw_token, %PasswordResetToken{}} on success.
  The raw token is sent via email; only the hash is stored.
  """
  def generate_reset_token(%User{} = user) do
    raw_token = :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)
    token_hash = :crypto.hash(:sha256, raw_token) |> Base.encode16(case: :lower)

    expires_at = DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.add(3600, :second)

    changeset =
      %PasswordResetToken{}
      |> PasswordResetToken.changeset(%{
        token_hash: token_hash,
        expires_at: expires_at,
        user_id: user.id
      })

    case Repo.insert(changeset) do
      {:ok, token} -> {:ok, raw_token, token}
      {:error, changeset} -> {:error, changeset}
    end
  end

  @doc """
  Looks up a user by a raw reset token.
  Validates the token exists, is not expired, and has not been used.
  Returns {:ok, user, token_record} or {:error, :invalid_token}.
  """
  def get_user_by_reset_token(raw_token) do
    token_hash = :crypto.hash(:sha256, raw_token) |> Base.encode16(case: :lower)

    now = DateTime.utc_now()

    token =
      PasswordResetToken
      |> where([t], t.token_hash == ^token_hash)
      |> where([t], is_nil(t.used_at))
      |> where([t], t.expires_at > ^now)
      |> Repo.one()

    case token do
      nil ->
        {:error, :invalid_token}

      token ->
        user = Repo.get!(User, token.user_id)
        {:ok, user, token}
    end
  end

  @doc """
  Resets a user's password using a valid reset token.
  Updates the password and marks the token as used.
  """
  def reset_password(%User{} = user, %PasswordResetToken{} = token, password) do
    Repo.transaction(fn ->
      # Update password
      user_changeset =
        user
        |> User.changeset(%{password: password})

      case Repo.update(user_changeset) do
        {:ok, updated_user} ->
          # Mark token as used
          token
          |> PasswordResetToken.changeset(%{
            used_at: DateTime.utc_now() |> DateTime.truncate(:second)
          })
          |> Repo.update!()

          {:ok, updated_user}

        {:error, changeset} ->
          Repo.rollback(changeset)
      end
    end)
  end

  @doc """
  Deletes password reset tokens older than the given age (default 24 hours).
  """
  def delete_expired_reset_tokens(age \\ {24, :hour}) do
    cutoff =
      DateTime.utc_now()
      |> DateTime.truncate(:second)
      |> DateTime.add(-elem(age, 0), elem(age, 1))

    PasswordResetToken
    |> where([t], t.inserted_at < ^cutoff)
    |> Repo.delete_all()
  end

  def has_members_besides?(tenant_id, user_id) do
    User
    |> where([u], u.tenant_id == ^tenant_id and u.id != ^user_id)
    |> Repo.exists?()
  end

  def dismiss_onboarding_checklist(%User{} = user) do
    user
    |> User.dismiss_onboarding_changeset()
    |> Repo.update()
  end
end
