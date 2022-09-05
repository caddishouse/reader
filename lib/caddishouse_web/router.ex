defmodule CaddishouseWeb.Router do
  use CaddishouseWeb, :router
  use Honeybadger.Plug

  import CaddishouseWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :put_root_layout, {CaddishouseWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  scope "/", CaddishouseWeb.Controllers do
    pipe_through :browser
    get "/privacy-policy", Pages, :privacy_policy
    get "/terms", Pages, :terms
  end

  scope "/auth", CaddishouseWeb.Controllers do
    pipe_through :browser
    get "/:provider", OAuth, :request
    get "/:provider/callback", OAuth, :callback
    post "/:provider/callback", OAuth, :callback
    delete "/logout", OAuth, :delete
  end

  scope "/", CaddishouseWeb.Live do
    pipe_through :browser

    live_session :default, on_mount: [{CaddishouseWeb.UserAuth, :current_user}] do
      live "/", Documents.Show, :index
      live "/media/:id", Documents.Show, :index
      live "/settings", Accounts.Show, :index
    end
  end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through [:fetch_session, :protect_from_forgery]

      live_dashboard "/dashboard", metrics: CaddishouseWeb.Telemetry
    end
  end
end
