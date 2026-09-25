defmodule TrebyWeb.Markdown do
  @moduledoc """
  Renders user- and assistant-authored Markdown (company and job descriptions,
  assistant replies) to sanitized safe HTML for display in the app.

  Parsing uses CommonMark plus GFM tables.
  """

  @doc """
  Converts Markdown text to sanitized safe HTML.

  Returns `{:safe, html}` ready for HEEx interpolation. Raw HTML, scripts,
  and dangerous URLs are stripped by `TrebyWeb.MarkdownScrubber`.
  """
  def to_safe_html(nil), do: Phoenix.HTML.raw("")

  def to_safe_html(text) when is_binary(text) do
    text
    |> MDEx.to_html!(extension: [table: true])
    |> HtmlSanitizeEx.Scrubber.scrub(TrebyWeb.MarkdownScrubber)
    |> Phoenix.HTML.raw()
  end
end
