if Code.ensure_loaded?(PhoenixStorybook) do
  defmodule TrebyWeb.Storybook do
    @moduledoc """
    Storybook backend for Treby's design system.

    Dev-only: mounted in `TrebyWeb.Router` when `Application.compile_env(:treby, :dev_routes)`
    is true (dev env). Uses `assets/css/app.css` tokens so previews match production.
    """

    use PhoenixStorybook,
      otp_app: :treby,
      content_path: Path.expand("../../storybook", __DIR__),
      css_path: "/assets/css/app.css",
      sandbox_class: "treby-sandbox",
      title: "Treby Design System",
      color_mode: true,
      color_mode_sandbox_dark_class: "dark"
  end
end
