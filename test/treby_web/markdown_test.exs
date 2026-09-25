defmodule TrebyWeb.MarkdownTest do
  use ExUnit.Case, async: true

  alias TrebyWeb.Markdown

  defp rendered(text) do
    {:safe, iodata} = Markdown.to_safe_html(text)
    IO.iodata_to_binary(iodata)
  end

  test "renders headings, emphasis, lists, and links" do
    html = rendered("# Hello\n\nSome **bold** and *italic* text.\n\n- one\n- two\n")

    assert html =~ "<h1>"
    assert html =~ "Hello"
    assert html =~ "<strong>bold</strong>"
    assert html =~ "<em>italic</em>"
    assert html =~ "<ul>"
    assert html =~ "<li>"
  end

  test "keeps http links, strips javascript URLs" do
    html = rendered("[ok](https://example.com) [bad](javascript:alert(1))")

    assert html =~ ~s(href="https://example.com")
    refute html =~ "javascript:"
  end

  test "strips scripts, raw HTML, and images" do
    html =
      rendered(
        "hi <script>alert(1)</script> <img src=\"https://example.com/x.png\"> <div>yo</div>"
      )

    refute html =~ "<script>"
    refute html =~ "<img"
    refute html =~ "<div>"
    assert html =~ "hi"
    assert html =~ "yo"
  end

  test "renders GFM tables with no attributes" do
    html = rendered("| Name | Role |\n|------|------|\n| Ada  | Dev  |\n")

    assert html =~ "<table>"
    assert html =~ "<thead>"
    assert html =~ "<tbody>"
    assert html =~ "<th>Name</th>"
    assert html =~ "<td>Ada</td>"
    refute html =~ "<table "
    refute html =~ "<td "
    refute html =~ "<th "
  end

  test "keeps tables while stripping scripts and dangerous URLs" do
    html =
      rendered(
        "| A | B |\n|---|---|\n| <script>alert(1)</script> | [bad](javascript:alert(1)) |\n"
      )

    assert html =~ "<table>"
    assert html =~ "<td>"
    refute html =~ "<script>"
    refute html =~ "javascript:"
  end

  test "handles nil and empty input" do
    assert {:safe, _} = Markdown.to_safe_html(nil)
    assert rendered("") == ""
  end
end
