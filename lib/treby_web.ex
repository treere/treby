defmodule TrebyWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, components, channels, and so on.

  This can be used in your application as:

      use TrebyWeb, :controller
      use TrebyWeb, :html

  The definitions below will be executed for every controller,
  component, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define additional modules and import
  those modules here.
  """

  def static_paths, do: ~w(assets fonts images favicon.ico robots.txt)

  def router do
    quote do
      use Phoenix.Router, helpers: false

      # Import common connection and controller functions to use in pipelines
      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
    end
  end

  def controller do
    quote do
      use Phoenix.Controller, formats: [:html, :json]

      use Gettext, backend: TrebyWeb.Gettext

      import Plug.Conn

      unquote(verified_routes())
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView

      import TrebyWeb.Hooks.SetLocale, only: [set_locale_from_session: 2]

      unquote(html_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      unquote(html_helpers())
    end
  end

  def html do
    quote do
      use Phoenix.Component

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_csrf_token: 0, view_module: 1, view_template: 1]

      # Include general helpers for rendering HTML
      unquote(html_helpers())
    end
  end

  defp html_helpers do
    quote do
      # Translation
      use Gettext, backend: TrebyWeb.Gettext

      # HTML escaping functionality
      import Phoenix.HTML
      # Core UI components (button will be delegated to DesignSystem)
      import TrebyWeb.CoreComponents, except: [button: 1, empty_state: 1]

      # Design system components
      import TrebyWeb.DesignSystem, only: [variant_classes: 1, badge_classes: 1, size_classes: 1]
      import TrebyWeb.DesignSystem.Button, only: [button: 1]
      import TrebyWeb.DesignSystem.Badge, only: [badge: 1]
      import TrebyWeb.DesignSystem.Card, only: [card: 1]
      import TrebyWeb.DesignSystem.Modal, only: [modal: 1]
      import TrebyWeb.DesignSystem.Dropdown, only: [dropdown: 1]
      import TrebyWeb.DesignSystem.Tabs, only: [tabs: 1]
      import TrebyWeb.DesignSystem.Feedback, only: [spinner: 1, skeleton: 1, toast: 1]
      import TrebyWeb.DesignSystem.Avatar, only: [avatar: 1]

      import TrebyWeb.DesignSystem.Pattern,
        only: [
          confirm_dialog: 1,
          page_header: 1,
          empty_state: 1,
          filter_bar: 1,
          form_section: 1,
          loading_overlay: 1
        ]

      # Common modules used in templates
      alias Phoenix.LiveView.JS
      alias TrebyWeb.Layouts

      # Routes generation with the ~p sigil
      unquote(verified_routes())
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: TrebyWeb.Endpoint,
        router: TrebyWeb.Router,
        statics: TrebyWeb.static_paths()
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/live_view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
