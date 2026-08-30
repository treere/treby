defmodule TrebyWeb.InviteFlowTest do
  use TrebyWeb.ConnCase, async: false
  import Phoenix.LiveViewTest
  import Ecto.Query

  alias Treby.{Tenants, Repo, Invites, Memberships}
  alias Treby.Accounts.User

  defp create_tenant(name) do
    {:ok, tenant} = Tenants.create_tenant(%{name: name})
    tenant
  end

  defp create_user(tenant, email, role \\ "member") do
    {:ok, user} =
      tenant
      |> Ecto.build_assoc(:users)
      |> User.changeset(%{email: email, password: "password123", name: "Test", role: role})
      |> Repo.insert()

    {:ok, _} =
      Memberships.create_membership(%{user_id: user.id, tenant_id: tenant.id, role: role})

    {tenant, user}
  end

  describe "invite to existing identity re-uses user" do
    test "invite to existing email does not create duplicate user, creates membership", %{
      conn: conn
    } do
      tenant_a = create_tenant("InviteA")
      tenant_b = create_tenant("InviteB")
      email = "reuse-#{System.unique_integer([:positive])}@test.com"
      {_ta, user} = create_user(tenant_a, email, "member")
      # Invite same email to tenant_b
      {:ok, invite} =
        Invites.create_invite(
          %{"email" => email, "role" => "member", "tenant_id" => tenant_b.id},
          %{role: "admin", id: user.id}
        )

      # Login as existing user and accept
      conn =
        conn
        |> init_test_session(%{"user_id" => user.id})
        |> get(~p"/invite/#{invite.token}")

      assert html_response(conn, 200) =~ "Join #{tenant_b.name}" or
               html_response(conn, 200) =~ "Join"

      # POST accept (existing same user, no user params)
      conn =
        post(
          conn |> recycle() |> init_test_session(%{"user_id" => user.id}),
          ~p"/invite/#{invite.token}",
          %{"user" => %{"name" => "Test"}}
        )

      # Should redirect to slug app, not create new user
      assert redirected_to(conn) == "/#{tenant_b.slug}/app"
      # No duplicate user
      lower = String.downcase(email)

      assert Repo.aggregate(
               from(u in User, where: fragment("lower(?)", u.email) == ^lower),
               :count,
               :id
             ) == 1

      # Membership created
      assert Memberships.member?(user.id, tenant_b.id)
    end

    test "idempotent re-accept does not duplicate membership", %{conn: conn} do
      tenant_a = create_tenant("IdemA")
      tenant_b = create_tenant("IdemB")
      email = "idem-#{System.unique_integer([:positive])}@test.com"
      {_ta, user} = create_user(tenant_a, email)

      {:ok, invite} =
        Invites.create_invite(
          %{"email" => email, "role" => "member", "tenant_id" => tenant_b.id},
          %{role: "admin", id: user.id}
        )

      # First accept
      conn1 =
        conn
        |> init_test_session(%{"user_id" => user.id})
        |> post(~p"/invite/#{invite.token}", %{"user" => %{"name" => "Test"}})

      assert redirected_to(conn1) == "/#{tenant_b.slug}/app"
      # Second attempt: try to create duplicate membership directly (idempotent)
      assert {:error, _} =
               Memberships.create_membership(%{
                 user_id: user.id,
                 tenant_id: tenant_b.id,
                 role: "member"
               })

      # Still only one membership
      assert Repo.aggregate(
               from(m in Treby.Memberships.Membership,
                 where: m.user_id == ^user.id and m.tenant_id == ^tenant_b.id
               ),
               :count,
               :id
             ) == 1

      # Show with same token after accept should be invalid (already accepted) - redirect to login
      conn2 =
        build_conn()
        |> init_test_session(%{"user_id" => user.id})
        |> get(~p"/invite/#{invite.token}")

      assert redirected_to(conn2) == "/#{tenant_b.slug}/app"
    end

    test "anon is prompted to log in", %{conn: conn} do
      tenant = create_tenant("AnonInvite")
      email = "anon-#{System.unique_integer([:positive])}@test.com"
      {_, user} = create_user(create_tenant("OtherAnon"), email)

      {:ok, invite} =
        Invites.create_invite(
          %{"email" => email, "role" => "member", "tenant_id" => tenant.id},
          %{role: "admin", id: user.id}
        )

      conn = get(conn, ~p"/invite/#{invite.token}")
      html = html_response(conn, 200)
      assert html =~ "Please log in as" or html =~ "Log in"
    end

    test "different logged-in user sees interstitial", %{conn: conn} do
      tenant = create_tenant("DiffInvite")
      email_alice = "alice-diff-#{System.unique_integer([:positive])}@test.com"
      email_bob = "bob-diff-#{System.unique_integer([:positive])}@test.com"
      {_, alice} = create_user(create_tenant("AliceHome"), email_alice)
      {_, bob} = create_user(create_tenant("BobHome"), email_bob)

      {:ok, invite} =
        Invites.create_invite(
          %{"email" => email_alice, "role" => "member", "tenant_id" => tenant.id},
          %{role: "admin", id: alice.id}
        )

      conn = conn |> init_test_session(%{"user_id" => bob.id}) |> get(~p"/invite/#{invite.token}")
      html = html_response(conn, 200)
      assert html =~ "You are logged in as" and html =~ email_bob
      assert html =~ email_alice
    end

    test "new email shows registration form", %{conn: conn} do
      tenant = create_tenant("NewInvite")
      email = "new-#{System.unique_integer([:positive])}@test.com"

      {:ok, invite} =
        Invites.create_invite(
          %{"email" => email, "role" => "member", "tenant_id" => tenant.id},
          %{role: "admin", id: Ecto.UUID.generate()}
        )

      conn = get(conn, ~p"/invite/#{invite.token}")
      html = html_response(conn, 200)
      assert html =~ "Accept Invite"
      assert html =~ email
    end
  end
end
