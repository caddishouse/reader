defmodule CaddishouseWeb.Controllers.Pages do
  @moduledoc false
  use CaddishouseWeb, :controller

  @spec privacy_policy(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def privacy_policy(conn, _params) do
    render(conn, "privacy_policy.html")
  end

  @spec terms(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def terms(conn, _params) do
    render(conn, "terms.html")
  end
end
