defmodule TrebyWeb.MarkdownScrubber do
  @moduledoc """
  Strict HTML allowlist for Markdown-rendered user content.

  Allows text formatting produced by Earmark (headings, lists, emphasis,
  links, quotes, code) and strips everything else, including images, tables,
  and any styling or scripting. Links are restricted to http/https.
  """

  use HtmlSanitizeEx, extend: :strip_tags

  allow_tag_with_these_attributes("p", [])
  allow_tag_with_these_attributes("h1", [])
  allow_tag_with_these_attributes("h2", [])
  allow_tag_with_these_attributes("h3", [])
  allow_tag_with_these_attributes("h4", [])
  allow_tag_with_these_attributes("ul", [])
  allow_tag_with_these_attributes("ol", [])
  allow_tag_with_these_attributes("li", [])
  allow_tag_with_these_attributes("strong", [])
  allow_tag_with_these_attributes("em", [])
  allow_tag_with_these_attributes("blockquote", [])
  allow_tag_with_these_attributes("code", [])
  allow_tag_with_these_attributes("pre", [])
  allow_tag_with_these_attributes("hr", [])
  allow_tag_with_these_attributes("br", [])
  allow_tag_with_uri_attributes("a", ["href"], ["http", "https"])
  allow_tag_with_these_attributes("a", ["title"])
end
