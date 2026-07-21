defmodule TrebyWeb.HomeLiveTest do
  use TrebyWeb.ConnCase

  import Phoenix.LiveViewTest

  describe "landing page" do
    test "renders the landing page", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/")

      assert html =~ "Treby"
      assert html =~ "Hire smarter with Treby"
    end

    test "has login link", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/")

      assert html =~ "Log in"
    end

    test "has register link", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/")

      assert html =~ "Get started"
    end

    test "shows feature cards", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/")

      assert html =~ "Job Management"
      assert html =~ "Candidate Tracking"
      assert html =~ "Interview Scheduling"
    end

    test "has footer", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/")

      assert html =~ "Modern applicant tracking"
      assert html =~ "All rights reserved"
    end
  end
end
