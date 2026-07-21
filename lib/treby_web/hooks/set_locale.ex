defmodule TrebyWeb.Hooks.SetLocale do
  @moduledoc """
  Helper to set locale in the socket from the session.
  """
  @supported_locales ~w(en it)
  @default_locale "en"

  def set_locale_from_session(socket, session) do
    locale = session["locale"] || @default_locale
    locale = if locale in @supported_locales, do: locale, else: @default_locale

    Gettext.put_locale(TrebyWeb.Gettext, locale)

    Phoenix.Component.assign(socket, locale: locale)
  end
end
