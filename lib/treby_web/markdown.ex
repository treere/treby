defmodule TrebyWeb.Markdown do
  @moduledoc """
  Renders user-authored Markdown (company and job descriptions) to sanitized
  safe HTML for display on public pages.
  """

  @doc """
  Converts Markdown text to sanitized safe HTML.

  Returns `{:safe, html}` ready for HEEx interpolation. Raw HTML, scripts,
  and dangerous URLs are stripped by `TrebyWeb.MarkdownScrubber`.
  """
  def to_safe_html(nil), do: Phoenix.HTML.raw("")

  def to_safe_html(text) when is_binary(text) do
    text
    |> MDEx.to_html!()
    |> HtmlSanitizeEx.Scrubber.scrub(TrebyWeb.MarkdownScrubber)
    |> Phoenix.HTML.raw()
  end
end
