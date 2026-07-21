defmodule TrebyWeb.Plugs.SetLocale do
  @moduledoc """
  Plug to resolve and set the locale for the current request.

  Resolution order:
  1. Session stored locale
  2. User preference (if logged in)
  3. Accept-Language header
  4. Default ("en")
  """
  @behaviour Plug

  import Plug.Conn

  @default_locale "en"
  @supported_locales ~w(en it)

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    locale = resolve_locale(conn)

    Gettext.put_locale(TrebyWeb.Gettext, locale)

    conn
    |> put_session(:locale, locale)
    |> assign(:locale, locale)
  end

  defp resolve_locale(conn) do
    session_locale = get_session(conn, :locale)

    cond do
      session_locale && locale_supported?(session_locale) ->
        session_locale

      header_locale = get_accept_language_locale(conn) ->
        header_locale

      true ->
        @default_locale
    end
  end

  defp get_accept_language_locale(conn) do
    case get_req_header(conn, "accept-language") do
      [accept_language | _] ->
        parse_accept_language(accept_language)

      _ ->
        nil
    end
  end

  defp parse_accept_language(header) do
    header
    |> String.split(",")
    |> Enum.map(&parse_language_tag/1)
    |> Enum.find_value(fn
      {lang, _quality} -> if locale_supported?(lang), do: lang
      _ -> nil
    end)
  end

  defp parse_language_tag(tag) do
    tag
    |> String.trim()
    |> String.split(";")
    |> case do
      [lang | rest] ->
        quality =
          rest
          |> Enum.find_value(1.0, fn
            "q=" <> q -> Float.parse(q) |> elem(0)
            _ -> nil
          end)

        lang = String.downcase(String.slice(lang, 0, 2))
        {lang, quality}
    end
  end

  defp locale_supported?(locale), do: locale in @supported_locales
end
