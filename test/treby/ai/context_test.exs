defmodule Treby.AI.ContextTest do
  use Treby.DataCase, async: false

  alias Treby.AI.Context
  alias Treby.{Repo, Tenants}
  alias Treby.Accounts.User
  alias Treby.Jobs.Job

  defp tenant_with_user do
    {:ok, tenant} =
      Tenants.create_tenant(%{
        name: "AI Ctx #{System.unique_integer([:positive])}",
        slug: "ai-ctx-#{System.unique_integer([:positive])}"
      })

    {:ok, user} =
      tenant
      |> Ecto.build_assoc(:users)
      |> User.changeset(%{
        email: "ai-ctx-#{System.unique_integer([:positive])}@test.com",
        password: "password123",
        name: "AI Ctx User",
        role: "admin"
      })
      |> Repo.insert()

    {tenant, user}
  end

  test "tenant comes from the socket, not from spoofed assigns or params" do
    {tenant, user} = tenant_with_user()
    {other_tenant, _} = tenant_with_user()

    membership = %{role: "admin"}

    socket = %{
      view: TrebyWeb.AiChatLive,
      assigns: %{
        current_user: user,
        current_tenant: tenant,
        current_membership: membership,
        tenant_id: other_tenant.id,
        current_params: %{"tenant_id" => other_tenant.id}
      }
    }

    ctx = Context.build(socket)

    assert ctx.tenant_id == tenant.id
    assert ctx.user_id == user.id
    assert ctx.role == "admin"
    assert ctx.params == %{"tenant_id" => other_tenant.id}
  end

  test "assigns snapshot excludes sensitive/internal keys" do
    {tenant, user} = tenant_with_user()

    socket = %{
      view: TrebyWeb.AiChatLive,
      assigns: %{
        current_user: user,
        current_tenant: tenant,
        current_membership: %{role: "member"},
        page_size: 25,
        __changed__: %{},
        flash: %{}
      }
    }

    ctx = Context.build(socket)

    assert ctx.assigns_snapshot["page_size"] == 25
    refute Map.has_key?(ctx.assigns_snapshot, "current_user")
    refute Map.has_key?(ctx.assigns_snapshot, "flash")
  end

  test "form_schema is derived from a changeset when present" do
    {tenant, user} = tenant_with_user()

    changeset =
      %Job{tenant_id: tenant.id}
      |> Job.changeset(%{title: "x", description: "y"})

    socket = %{
      view: TrebyWeb.AiChatLive,
      assigns: %{
        current_user: user,
        current_tenant: tenant,
        current_membership: %{role: "admin"},
        form: changeset
      }
    }

    ctx = Context.build(socket)
    field_names = Enum.map(ctx.form_schema["fields"], & &1["name"])

    assert "title" in field_names
    assert "description" in field_names
  end

  test "form_schema is nil without a form" do
    {tenant, user} = tenant_with_user()

    socket = %{
      view: TrebyWeb.AiChatLive,
      assigns: %{
        current_user: user,
        current_tenant: tenant,
        current_membership: %{role: "admin"}
      }
    }

    assert Context.build(socket).form_schema == nil
  end
end
