defmodule TrebyWeb.JobsCustomFieldTest do
  use TrebyWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Treby.{Tenants, Repo, Customization}
  alias Treby.Accounts.User

  defp setup_tenant do
    suffix = System.unique_integer([:positive])

    {:ok, tenant} =
      Tenants.create_tenant(%{name: "JobCF #{suffix}", slug: "jobcf-#{suffix}"})

    {:ok, user} =
      tenant
      |> Ecto.build_assoc(:users)
      |> User.changeset(%{
        email: "jobcf-#{suffix}@test.com",
        password: "password123",
        name: "JobCF User",
        role: "admin"
      })
      |> Repo.insert()

    {:ok, _} =
      Treby.Memberships.create_membership(%{
        user_id: user.id,
        tenant_id: tenant.id,
        role: "admin"
      })

    {tenant, user}
  end

  test "required job custom field empty shows per-field error not just flash", %{conn: conn} do
    {tenant, user} = setup_tenant()

    {:ok, _field} =
      Customization.create_custom_field(%{
        tenant_id: tenant.id,
        name: "Budget",
        field_type: "text",
        applies_to: "job",
        required: true
      })

    conn = init_test_session(conn, %{"user_id" => user.id})
    {:ok, view, _html} = live(conn, "/#{tenant.slug}/app/jobs/new")

    html =
      view
      |> form("#job-create-form", %{
        "job" => %{"title" => "Test Job", "description" => "desc", "status" => "open"},
        "custom_fields" => %{}
      })
      |> render_submit()

    # flash generico
    assert html =~ "Please fill in required fields"
    assert html =~ "Budget"
    # per-field highlight: input-error + can't be blank sotto Budget
    assert html =~ "can&#39;t be blank" or html =~ "can&apos;t be blank",
           "expected per-field can't be blank for Budget, got: #{String.slice(html, 0, 3000)}"

    assert html =~ "input-error" or html =~ "text-red",
           "expected input-error class for Budget field"
  end

  test "required job custom field filled passes and redirects", %{conn: conn} do
    {tenant, user} = setup_tenant()

    {:ok, field} =
      Customization.create_custom_field(%{
        tenant_id: tenant.id,
        name: "Budget",
        field_type: "text",
        applies_to: "job",
        required: true
      })

    conn = init_test_session(conn, %{"user_id" => user.id})
    {:ok, view, _html} = live(conn, "/#{tenant.slug}/app/jobs/new")

    result =
      view
      |> form("#job-create-form", %{
        "job" => %{"title" => "Test Job", "description" => "desc", "status" => "open"},
        "custom_fields" => %{to_string(field.id) => "100k"}
      })
      |> render_submit()

    assert {:error, {:live_redirect, %{to: to}}} = result
    assert to =~ "/jobs/"
  end
end
