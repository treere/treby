defmodule TrebyWeb.DesignSystem.PatternTest do
  use TrebyWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import TrebyWeb.DesignSystem.Pattern

  describe "confirm_dialog" do
    test "renders when show is true" do
      html =
        render_component(&confirm_dialog/1, %{
          id: "test-dialog",
          show: true,
          title: "Delete?",
          message: "Are you sure?",
          on_confirm: "delete"
        })

      assert html =~ "Delete?"
      assert html =~ "Confirm"
    end
  end

  describe "page_header" do
    test "renders title" do
      html = render_component(&page_header/1, %{title: "Dashboard"})
      assert html =~ "Dashboard"
    end

    test "renders breadcrumbs" do
      html =
        render_component(&page_header/1, %{
          title: "Edit",
          breadcrumbs: [%{label: "Home", href: "/"}, %{label: "Users"}]
        })

      assert html =~ "Home"
    end
  end

  describe "empty_state" do
    test "renders title" do
      html = render_component(&empty_state/1, %{title: "No results"})
      assert html =~ "No results"
    end
  end

  describe "filter_bar" do
    test "renders fields" do
      html =
        render_component(&filter_bar/1, %{
          id: "filters",
          fields: [%{key: "status", label: "Status", value: ""}],
          on_change: "filter",
          on_reset: "reset"
        })

      assert html =~ "Status"
      assert html =~ "Reset"
    end
  end

  describe "form_section" do
    test "renders title" do
      html = render_component(&form_section/1, %{title: "Details"})
      assert html =~ "Details"
    end
  end

  describe "loading_overlay" do
    test "shows spinner when loading" do
      html = render_component(&loading_overlay/1, %{loading: true, label: "Loading..."})

      assert html =~ "animate-spin"
      assert html =~ "Loading..."
    end
  end
end
