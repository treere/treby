defmodule TrebyWeb.DarkThemeContrastTest do
  use TrebyWeb.ConnCase, async: false

  alias Treby.Jobs.Job
  alias TrebyWeb.DesignSystem

  describe "DesignSystem helpers are theme-aware" do
    test "secondary variant has dark overrides" do
      classes = DesignSystem.variant_classes("secondary")
      assert classes =~ "dark:bg-zinc-800"
      assert classes =~ "dark:text-zinc-100"
      assert classes =~ "dark:border-zinc-700"
    end

    test "ghost variant has dark overrides" do
      classes = DesignSystem.variant_classes("ghost")
      assert classes =~ "dark:text-zinc-300"
      assert classes =~ "dark:hover:bg-zinc-800"
    end

    test "outline variant has dark overrides" do
      classes = DesignSystem.variant_classes("outline")
      assert classes =~ "dark:bg-zinc-800"
      assert classes =~ "dark:text-zinc-200"
    end

    test "badge variants have dark overrides" do
      for variant <- ~w(default success warning danger info) do
        classes = DesignSystem.badge_classes(variant)
        assert classes =~ "dark:"
        assert classes =~ "dark:text-"
        assert classes =~ "dark:bg-"
      end
    end

    test "input_classes includes dark placeholder and bg" do
      classes = DesignSystem.input_classes()
      assert classes =~ "dark:bg-zinc-800"
      assert classes =~ "dark:border-zinc-700"
      assert classes =~ "dark:text-zinc-100"
      assert classes =~ "dark:placeholder:text-zinc-400"
    end
  end

  describe "careers pages: contrast and i18n" do
    test "global careers search input is dark-aware", %{conn: conn} do
      conn = get(conn, "/careers")
      html = html_response(conn, 200)
      assert html =~ "dark:bg-zinc-800"
      assert html =~ "dark:text-zinc-100"
      assert html =~ "dark:placeholder:text-zinc-400"
      # public header
      assert html =~ "Treby"
      assert html =~ "phx:set-theme"
    end

    test "tenant careers show back link is gettext and dark-aware", %{conn: conn} do
      {:ok, tenant} =
        Treby.Tenants.create_tenant(%{
          name: "Show Test",
          slug: "show-test-#{System.unique_integer([:positive])}"
        })

      {:ok, pipeline} =
        Treby.Pipeline.create_pipeline(%{
          name: "Contrast Pipeline",
          tenant_id: tenant.id,
          is_default: true
        })

      {:ok, job} =
        tenant
        |> Ecto.build_assoc(:jobs)
        |> Job.changeset(%{
          title: "Engineer",
          description: "Desc",
          pipeline_id: pipeline.id
        })
        |> Treby.Repo.insert()

      conn = get(conn, "/#{tenant.slug}/careers/#{job.id}")
      html = html_response(conn, 200)
      # back link should have dark variant and be gettext
      assert html =~ "dark:text-zinc-300"
      assert html =~ "Back to all positions" or html =~ "Torna a tutte le posizioni"
    end
  end

  describe "dashboard headings" do
    test "headings include dark:text-zinc-100" do
      html = File.read!("lib/treby_web/live/dashboard_live.ex")
      assert html =~ "text-zinc-900 dark:text-zinc-100"
      refute html =~ "text-lg font-semibold mb-4\""
      # check weekly stats muted mapping canonical
      assert html =~ "text-zinc-500 dark:text-zinc-400"
      refute html =~ "text-zinc-400 dark:text-zinc-500"
    end
  end

  describe "auth pages" do
    test "login forgot password link has dark variant", %{conn: conn} do
      conn = get(conn, "/login")
      html = html_response(conn, 200)
      assert html =~ "Forgot your password?"
      assert html =~ "dark:text-orange-300"
    end

    test "password pages have homepage link", %{conn: conn} do
      conn = get(conn, "/reset-password")
      html = html_response(conn, 200)
      assert html =~ "Treby"
      assert html =~ "href=\"/\""
    end
  end

  describe "public header" do
    test "careers and password pages render public_header" do
      html_global = File.read!("lib/treby_web/live/careers_live/global_index.ex")
      assert html_global =~ "public_header"

      html_show = File.read!("lib/treby_web/live/careers_live/show.ex")
      assert html_show =~ "public_header"

      html_pass_new = File.read!("lib/treby_web/controllers/password_reset_html/new.html.heex")
      assert html_pass_new =~ "Treby"
      assert html_pass_new =~ "auth_toolbar"
    end
  end
end
