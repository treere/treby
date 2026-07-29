defmodule TrebyWeb.DesignSystem.CoreTest do
  use TrebyWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import TrebyWeb.DesignSystem.Card
  import TrebyWeb.DesignSystem.Modal
  import TrebyWeb.DesignSystem.Tabs
  import TrebyWeb.DesignSystem.Feedback
  import TrebyWeb.DesignSystem.Avatar

  describe "card" do
    test "renders with card class" do
      html = render_component(&card/1, %{})
      assert html =~ "card"
    end
  end

  describe "modal" do
    test "renders when show is true" do
      html = render_component(&modal/1, %{id: "test", show: true, title: "My Modal"})
      assert html =~ "My Modal"
    end
  end

  describe "tabs" do
    test "renders with active tab" do
      html =
        render_component(&tabs/1, %{
          id: "test-tabs",
          tabs: [%{key: "active", label: "Active"}, %{key: "all", label: "All"}],
          active_tab: "active"
        })

      assert html =~ "tab-active"
    end
  end

  describe "spinner" do
    test "renders with animate class" do
      html = render_component(&spinner/1, %{})
      assert html =~ "animate-spin"
    end
  end

  describe "skeleton" do
    test "renders placeholder" do
      html = render_component(&skeleton/1, %{variant: "text"})
      assert html =~ "animate-pulse"
    end
  end

  describe "avatar" do
    test "renders with initials" do
      html = render_component(&avatar/1, %{initials: "JD"})
      assert html =~ "JD"
    end
  end
end
