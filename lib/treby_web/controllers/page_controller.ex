defmodule TrebyWeb.PageController do
  use TrebyWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
