defmodule TrebyWeb.RegistrationController do
  use TrebyWeb, :controller

  import Phoenix.Component, only: [to_form: 2]

  alias Treby.{Tenants, Repo}
  alias Treby.Accounts
  alias Treby.Accounts.User
  alias TrebyWeb.Registration

  def new(conn, _params) do
    changeset = Registration.changeset(%Registration{}, %{})
    render(conn, "new.html", form: to_form(changeset, as: :user))
  end

  def create(conn, %{"user" => user_params}) do
    changeset = Registration.changeset(%Registration{}, user_params)

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
        case Tenants.create_tenant(%{name: user_params["company_name"]}) do
          {:ok, tenant} ->
            case tenant
                 |> Ecto.build_assoc(:users)
                 |> User.changeset(%{
                   email: user_params["email"],
                   password: user_params["password"],
                   name: user_params["name"],
                   role: "admin"
                 })
                 |> Repo.insert() do
              {:ok, user} ->
                conn
                |> put_session("user_id", user.id)
                |> put_session("tenant_id", tenant.id)
                |> put_flash(:info, "Welcome to Treby!")
                |> redirect(to: ~p"/app")

              {:error, _changeset} ->
                conn
                |> put_flash(:error, "Could not create your account")
                |> redirect(to: ~p"/register")
            end

          {:error, _changeset} ->
            conn
            |> put_flash(:error, "Could not create company")
            |> redirect(to: ~p"/register")
        end
    end
  end
end
