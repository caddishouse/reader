defmodule CaddishouseWeb.Controllers.OAuth do
  @moduledoc false
  use CaddishouseWeb, :controller
  plug Ueberauth

  alias Ueberauth.Strategy.Helpers
  alias CaddishouseWeb.UserAuth
  alias Caddishouse.Accounts.Users
  require Logger

  @spec request(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def request(conn, _params) do
    render(conn, "request.html", callback_url: Helpers.callback_url(conn))
  end

  @spec delete(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def delete(conn, _params) do
    conn
    |> clear_session()
    |> redirect(to: "/")
  end

  def callback(%{assigns: %{ueberauth_failure: fails}} = conn, _params) do
    Logger.error(fails)

    conn
    |> redirect(to: "/")
  end

  @spec callback(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, %{"provider" => provider}) do
    current_user = conn.assigns.current_user

    if current_user do
      Users.create_or_update_oauth!(current_user, provider, auth)
      redirect(conn, to: "/")
    else
      # TODO get_or_create_by_email AND provider
      user = Users.get_or_create_by_email(auth.info.email)
      Users.create_or_update_oauth!(user, provider, auth)

      conn
      |> UserAuth.log_in_user(user)
    end
  end
end
