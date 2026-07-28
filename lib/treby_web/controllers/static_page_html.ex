defmodule TrebyWeb.StaticPageHTML do
  @moduledoc """
  This module contains templates rendered by StaticPageController.
  """

  use TrebyWeb, :html

  embed_templates "static_page_html/*"
end
