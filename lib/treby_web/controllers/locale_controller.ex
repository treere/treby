defmodule TrebyWeb.LocaleController do
  use TrebyWeb, :controller

  @supported_locales ~w(en it)

  def set(conn, %{"locale" => locale, "return_to" => return_to}) do
    locale = if locale in @supported_locales, do: locale, else: "en"

    conn
    |> put_session(:locale, locale)
    |> redirect(to: return_to || "/app")
  end

  def set(conn, %{"locale" => locale}) do
    locale = if locale in @supported_locales, do: locale, else: "en"

    return_to =
      conn
      |> get_req_header("referer")
      |> List.first("/app")
      |> URI.parse()
      |> Map.get(:path, "/app")

    conn
    |> put_session(:locale, locale)
    |> redirect(to: return_to)
  end
end
