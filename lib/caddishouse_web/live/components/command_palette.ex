defmodule CaddishouseWeb.Live.Components.CommandPalette do
  @moduledoc false
  use CaddishouseWeb, :live_component
  alias Caddishouse.OAuth2.Providers
  alias Caddishouse.Accounts.Users
  alias Caddishouse.Documents
  alias CaddishouseWeb.Live.Components.Toasts

  @impl true
  def update(assigns, socket) do
    socket =
      assign_new(socket, :recently_viewed, fn ->
        if assigns.current_user do
          Documents.recently_viewed(assigns.current_user)
        end
      end)

    {:ok,
     assign(socket,
       current_user: assigns.current_user,
       id: assigns.id
     )
     |> reset_search()}
  end

  @impl true
  def handle_event("search", %{"search" => %{"query" => ""}}, socket) do
    {:noreply, reset_search(socket)}
  end

  @impl true
  def handle_event(
        "search",
        %{"search" => %{"query" => _query}},
        %{assigns: %{current_user: nil}} = socket
      ) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("search", %{"search" => %{"query" => query}}, socket) do
    current_user = socket.assigns.current_user

    # TODO preload providers?
    oauth_users =
      current_user
      |> Users.list_oauth_users()

    existing_results = Documents.search(current_user, query)

    external_results =
      Enum.flat_map(oauth_users, fn oauth_user ->
        case Providers.search(socket.assigns.current_user, oauth_user, query) do
          {:ok, results} ->
            Enum.map(
              results,
              &Map.merge(&1, %{oauth_user_email: oauth_user.email, oauth_user_id: oauth_user.id})
            )

          _ ->
            []
        end
      end)

    {:noreply,
     socket |> assign(external_results: external_results, existing_results: existing_results)}
  end

  @impl true
  def handle_event(
        "import",
        %{
          "oauth_user_id" => oauth_user_id,
          "source_key" => source_key,
          "name" => name
        },
        socket
      ) do
    current_user = socket.assigns.current_user
    # TODO preload and pull from preload...
    oauth_user = Users.get_oauth_user_by_id!(oauth_user_id)

    case Documents.import_media(
           current_user,
           oauth_user,
           source_key,
           name
         ) do
      {:ok, :processing_media} ->
        Toasts.info("Importing file:<br/><strong>#{name}</strong>")
        {:noreply, socket}

      {:ok, media} ->
        {:noreply,
         push_redirect(socket, to: Routes.documents_show_path(socket, :index, media.id))}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div phx-hook="CommandPalette" id="command-palette">
      <.search_input myself={@myself} />
      <%= if @current_user do %>
        <%= cond do %>
          <% !Enum.empty?(@document_results) -> %>
            <.document_results results={@document_results} />
          <% Enum.empty?(@existing_results) and Enum.empty?(@external_results) -> %>
            <%= if Map.has_key?(assigns, :recently_viewed) do %>
              <.results name="Recently Viewed" results={@recently_viewed}>
                <:result :let={result}>
                  <.internal_result socket={@socket} myself={@myself} result={result} />
                </:result>
              </.results>
            <% end %>
          <% true -> %>
            <.results name="Internal Documents" results={@existing_results}>
              <:result :let={result}>
                <.internal_result socket={@socket} myself={@myself} result={result} />
              </:result>
            </.results>
            <.results name="External Documents" results={@external_results}>
              <:result :let={result}>
                <.external_result socket={@socket} myself={@myself} result={result} />
              </:result>
            </.results>
        <% end %>
      <% else %>
        <div class="max-h-80 scroll-py-10 scroll-py-10 scroll-pb-2 scroll-pb-2 space-y-4 overflow-y-auto p-4 pb-2">
          <h2 class="text-xs font-semibold text-gray-900" role="none">
            In order to load a document you must log-in.
          </h2>
        </div>
      <% end %>
    </div>
    """
  end

  defp results(assigns) do
    ~H"""
    <ul class="max-h-80 scroll-py-10 scroll-py-10 scroll-pb-2 scroll-pb-2 space-y-4 overflow-y-auto p-4 pb-2">
      <li role="none">
        <h2 class="text-xs font-semibold text-gray-900" role="none"><%= @name %></h2>
        <ul class="-mx-4 mt-2 text-sm text-gray-700" role="none">
          <%= for result <- @results do %>
            <%= render_slot(@result, result) %>
          <% end %>
        </ul>
      </li>
    </ul>
    """
  end

  defp internal_result(assigns) do
    ~H"""
    <li
      data-result-id={@result.id}
      class="group flex cursor-default select-none items-center px-3 py-2"
    >
      <.icon name="document" outlined class="h-6 w-6 flex-none text-gray-900 text-opacity-40" />
      <a
        href={Routes.documents_show_path(@socket, :index, @result.id)}
        class="text-left ml-3 flex-auto truncate"
      >
        <%= @result.name %>
      </a>
    </li>
    """
  end

  defp external_result(assigns) do
    ~H"""
    <li
      data-result-id={@result.id}
      class="group flex md:flex-row flex-col md:justify-between cursor-default select-none md:items-center px-3 py-2"
    >
      <span class="flex">
        <.provider_to_icon provider={@result.source} />
        <a
          href="#"
          phx-target={@myself}
          phx-click="import"
          phx-value-name={@result.name}
          phx-value-source={@result.source}
          phx-value-source_key={@result.id}
          phx-value-oauth_user_id={@result.oauth_user_id}
          class="text-left ml-3 flex-auto truncate"
        >
          <%= @result.name %>
        </a>
      </span>
      <span>
        <.badge><%= @result.oauth_user_email %></.badge>
      </span>
    </li>
    """
  end

  defp search_input(assigns) do
    ~H"""
    <div class="relative">
      <.form :let={f} for={%{}} as={:search} phx-change="search" phx-target={@myself}>
        <.icon
          name="magnifying-glass-circle"
          class="pointer-events-none absolute top-3.5 left-4 h-5 w-5 text-gray-400"
        />
        <%= text_input(f, :query,
          autocomplete: "off",
          phx_debounce: 500,
          role: "combobox",
          placeholder: "Search...",
          class:
            "h-12 w-full border-0 bg-transparent pl-11 pr-4 text-gray-800 placeholder-gray-400 focus:ring-0 sm:text-sm"
        ) %>
      </.form>
    </div>
    """
  end

  defp document_results(assigns) do
    ~H"""

    """
  end

  defp provider_to_icon(assigns) do
    ~H"""
    <%= case @provider do %>
      <% :google -> %>
        <Components.Logos.google_drive class="h-5 h-5 flex-none" />
      <% _ -> %>
        <.icon name="document" outlined class="h-6 w-6 flex-none text-gray-900 text-opacity-40" />
    <% end %>
    """
  end

  defp reset_search(socket) do
    assign(socket, document_results: [], external_results: [], existing_results: [])
  end
end
