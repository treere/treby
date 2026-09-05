defmodule TrebyWeb.DesignSystem.BadgeTest do
  use TrebyWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import TrebyWeb.DesignSystem.Badge

  describe "badge" do
    test "renders default" do
      html = render_component(&badge/1, %{})
      assert html =~ "rounded-full"
    end

    test "renders success variant" do
      html = render_component(&badge/1, %{variant: "success"})
      assert html =~ "bg-emerald-50"
    end
  end
end
