defmodule TrebyWeb.Hooks.SetLocale do
  @moduledoc """
  LiveView on_mount hook that sets locale in the socket from the session.
  Also provides a legacy function for LiveViews not in a live_session.
  """
  @supported_locales ~w(en it)
  @default_locale "en"

  def on_mount(:set_locale, _params, session, socket) do
    {:cont, set_locale_from_session(socket, session)}
  end

  def set_locale_from_session(socket, session) do
    locale = session["locale"] || @default_locale
    locale = if locale in @supported_locales, do: locale, else: @default_locale

    Gettext.put_locale(TrebyWeb.Gettext, locale)

    Phoenix.Component.assign(socket, locale: locale)
  end
end
