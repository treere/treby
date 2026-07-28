defmodule TrebyWeb.RegistrationController do
  use TrebyWeb, :controller

  alias Treby.{Tenants, Repo}
  alias Treby.Accounts.User

  def new(conn, _params) do
    render(conn, "new.html")
  end

  def create(conn, %{"user" => user_params}) do
    cond do
      user_params["password"] != user_params["password_confirmation"] ->
        conn
        |> put_flash(:error, "Passwords do not match")
        |> redirect(to: ~p"/register")

      user_params["tos_accepted"] != "true" ->
        conn
        |> put_flash(:error, "You must accept the Terms of Service")
        |> redirect(to: ~p"/register")

      true ->
        case Tenants.create_tenant(%{
               name: user_params["company_name"],
               slug: user_params["company_slug"]
             }) do
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
                |> put_flash(:error, "Email already registered or invalid data")
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
