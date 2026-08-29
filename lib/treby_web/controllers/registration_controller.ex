defmodule TrebyWeb.RegistrationController do
  use TrebyWeb, :controller

  import Phoenix.Component, only: [to_form: 1, to_form: 2]

  alias Treby.{Tenants, Repo}
  alias Treby.Accounts
  alias Treby.Accounts.User
  alias Treby.RegistrationVerification
  alias Treby.RegistrationOtpEmail
  alias TrebyWeb.Registration

  def new(conn, _params) do
    case get_session(conn, "verified_email") do
      nil ->
        changeset = Registration.email_changeset(%Registration{}, %{})
        render(conn, "new.html", form: to_form(changeset, as: :user))

      verified_email ->
        changeset = Registration.changeset(%Registration{}, %{"email" => verified_email})

        render(conn, "setup.html",
          form: to_form(changeset, as: :user),
          verified_email: verified_email
        )
    end
  end

  def create(conn, %{"user" => user_params}) do
    case get_session(conn, "verified_email") do
      nil -> send_verification_code(conn, user_params)
      verified_email -> create_account(conn, user_params, verified_email)
    end
  end

  def create(conn, _params) do
    changeset = Registration.email_changeset(%Registration{}, %{})

    conn
    |> put_status(422)
    |> render("new.html", form: to_form(changeset, as: :user, action: :insert))
  end

  def verify(conn, _params) do
    case get_session(conn, "registration_email") do
      nil ->
        conn
        |> put_flash(:error, gettext("Start by entering your email address"))
        |> redirect(to: ~p"/register")

      email ->
        resend_form = to_form(%{"email" => email}, as: :user)

        render(conn, "verify.html",
          email: email,
          form: to_form(%{"code" => ""}),
          resend_form: resend_form
        )
    end
  end

  def verify_code(conn, %{"code" => code}) do
    case get_session(conn, "registration_email") do
      nil ->
        conn
        |> put_flash(:error, gettext("Start by entering your email address"))
        |> redirect(to: ~p"/register")

      email ->
        case RegistrationVerification.verify_code(email, code) do
          :ok ->
            conn
            |> put_session("verified_email", email)
            |> delete_session("registration_email")
            |> put_flash(:info, gettext("Email verified!"))
            |> redirect(to: ~p"/register")

          {:error, _reason} ->
            RegistrationVerification.record_failed_attempt(email)

            conn
            |> put_flash(:error, gettext("Invalid or expired code. Please try again."))
            |> redirect(to: ~p"/register/verify")
        end
    end
  end

  def verify_code(conn, _params) do
    conn
    |> put_flash(:error, gettext("Enter the code you received by email"))
    |> redirect(to: ~p"/register/verify")
  end

  defp send_verification_code(conn, user_params) do
    changeset = Registration.email_changeset(%Registration{}, user_params)

    cond do
      not changeset.valid? ->
        conn
        |> put_status(422)
        |> render("new.html", form: to_form(changeset, as: :user, action: :insert))

      Accounts.email_registered?(user_params["email"]) ->
        changeset = Ecto.Changeset.add_error(changeset, :email, "has already been taken")

        conn
        |> put_status(422)
        |> render("new.html", form: to_form(changeset, as: :user, action: :insert))

      true ->
        email = user_params["email"]

        case RegistrationVerification.generate_code(email) do
          {:ok, code} ->
            RegistrationOtpEmail.otp_email(email, code)
            |> Treby.Mailer.deliver()

            conn
            |> put_session("registration_email", email)
            |> put_flash(:info, gettext("We sent a verification code to %{email}", email: email))
            |> redirect(to: ~p"/register/verify")

          {:error, :rate_limited} ->
            conn
            |> put_flash(:error, gettext("Please wait a moment before requesting another code"))
            |> redirect(to: ~p"/register/verify")

          {:error, _} ->
            conn
            |> put_flash(:error, gettext("Something went wrong. Please try again."))
            |> redirect(to: ~p"/register")
        end
    end
  end

  defp create_account(conn, user_params, verified_email) do
    user_params = Map.put(user_params, "email", verified_email)
    changeset = Registration.changeset(%Registration{}, user_params)

    cond do
      not changeset.valid? ->
        conn
        |> put_status(422)
        |> render("setup.html",
          form: to_form(changeset, as: :user, action: :insert),
          verified_email: verified_email
        )

      Accounts.email_registered?(verified_email) ->
        changeset = Ecto.Changeset.add_error(changeset, :email, "has already been taken")

        conn
        |> put_status(422)
        |> render("setup.html",
          form: to_form(changeset, as: :user, action: :insert),
          verified_email: verified_email
        )

      true ->
        case Tenants.create_tenant(%{name: Ecto.Changeset.get_field(changeset, :company_name)}) do
          {:ok, tenant} ->
            case tenant
                 |> Ecto.build_assoc(:users)
                 |> User.changeset(%{
                   email: verified_email,
                   password: user_params["password"],
                   name: user_params["name"],
                   role: "admin"
                 })
                 |> Repo.insert() do
              {:ok, user} ->
                conn
                |> put_session("user_id", user.id)
                |> put_session("tenant_id", tenant.id)
                |> delete_session("verified_email")
                |> put_flash(:info, gettext("Welcome to Treby!"))
                |> redirect(to: ~p"/app")

              {:error, _changeset} ->
                conn
                |> put_flash(:error, gettext("Could not create your account"))
                |> redirect(to: ~p"/register")
            end

          {:error, _changeset} ->
            conn
            |> put_flash(:error, gettext("Could not create company"))
            |> redirect(to: ~p"/register")
        end
    end
  end
end
