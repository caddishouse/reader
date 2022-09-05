defmodule CaddishouseWeb.Live.Components.Settings do
  @moduledoc false
  use CaddishouseWeb, :live_component
  alias Caddishouse.Accounts.Users

  @impl true
  def update(assigns, socket) do
    current_user = assigns.current_user

    socket =
      socket
      |> assign(assigns)
      |> assign_new(:oauth_users, fn ->
        if current_user do
          current_user
          |> Users.list_oauth_users()
        end
      end)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="p-5 space-y-3">
      <div>
        <div class="block mb-1 text-sm font-semibold text-gray-700">
          Connect your accounts
        </div>

        <div class="grid md:grid-cols-3">
          <a
            class="w-full bg-red-700 hover:bg-red-800 text-white flex py-2 px-4 focus:outline-none focus:shadow-outline"
            href={Routes.o_auth_path(@socket, :request, :google)}
          >
            <Components.Logos.google_drive class="h-5 h-5 flex-none mr-2" /> Google Drive
          </a>
        </div>
      </div>
      <%= unless is_nil(@current_user) do %>
        <.connected_accounts oauth_users={@oauth_users} />
      <% end %>
      <%= if @current_user do %>
        <div>
          <%= link("Log out",
            method: :delete,
            to: Routes.o_auth_path(@socket, :delete),
            class:
              "rounded bg-indigo-400 hover:bg-indigo-600 text-white py-2 px-4 focus:outline-none focus:shadow-outline"
          ) %>
        </div>
      <% end %>
    </div>
    """
  end

  defp connected_accounts(assigns) do
    ~H"""
    <div>
      <dt class="block mb-1 text-sm font-semibold text-gray-700">
        Connected Accounts
      </dt>

      <dd class="text-sm text-gray-900">
        <ul role="list" class="border border-gray-200 rounded-md divide-y divide-gray-200">
          <%= for oauth_user <- @oauth_users do %>
            <li class="pl-3 pr-4 py-3 flex items-center justify-between text-sm">
              <div class="w-0 flex-1 flex items-center">
                <Components.Logos.google_drive class="h-5 h-5 flex-none mr-2" />
                <span class="ml-2 flex-1 w-0 truncate">
                  <%= oauth_user.email %>
                </span>
              </div>
            </li>
          <% end %>
        </ul>
      </dd>
      <div class="mt-2 prose text-xs">
        <p>
          <a target="_blank" href="https://myaccount.google.com/permissions">Click here</a>
          to disconnect your Google Drive. While you will no longer be able to search your Google Drive account, the files which you already imported will continue to exist on this platform until you choose delete them.
        </p>
        <p>
          If you disconnect all of your accounts and are logged-out, you will no longer be able to access your current account again and it will be scheduled to automatically be deleted.
        </p>
      </div>
    </div>
    """
  end
end
