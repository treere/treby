defmodule TrebyWeb.DesignSystem.ButtonTest do
  use TrebyWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import TrebyWeb.DesignSystem.Button

  describe "button" do
    test "renders primary variant" do
      html = render_component(&button/1, %{variant: "primary"})
      assert html =~ "btn btn-primary"
    end

    test "renders danger variant" do
      html = render_component(&button/1, %{variant: "danger"})
      assert html =~ "btn btn-error"
    end

    test "renders with size" do
      html = render_component(&button/1, %{size: "sm"})
      assert html =~ "btn-sm"
    end

    test "renders disabled state" do
      html = render_component(&button/1, %{disabled: true})
      assert html =~ "disabled"
    end

    test "renders loading state" do
      html = render_component(&button/1, %{loading: true})
      assert html =~ "animate-spin"
    end

    test "renders type=submit when passed" do
      html = render_component(&button/1, %{type: "submit"})
      assert html =~ ~s{type="submit"}
    end

    test "defaults to type=button when not passed" do
      html = render_component(&button/1, %{})
      assert html =~ ~s{type="button"}
      refute html =~ ~s{type="submit"}
    end
  end
end
