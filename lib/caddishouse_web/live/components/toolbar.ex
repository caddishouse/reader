defmodule CaddishouseWeb.Live.Components.Toolbar do
  @moduledoc false
  use CaddishouseWeb, :live_component
  alias CaddishouseWeb.Live.Components.{CommandPalette, Modal, Settings, About}
  alias Caddishouse.Documents

  def update_total_pages(total_pages) do
    send_update(__MODULE__, id: "toolbar", total_pages: total_pages)
  end

  def update_current_page(current_page) do
    send_update(__MODULE__, id: "toolbar", current_page: current_page)
  end

  @impl true
  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  @impl true
  def handle_event("show-command-palette", _, socket) do
    Modal.show(CommandPalette, %{
      id: "command-palette"
    })

    {:noreply, socket}
  end

  @impl true
  def handle_event("show-settings", _, socket) do
    Modal.show(Settings, %{
      id: "settings"
    })

    {:noreply, socket}
  end

  @impl true
  def handle_event("show-about", _, socket) do
    Modal.show(About, %{
      id: "about"
    })

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div
      id={"toolbar-#{Documents.metadata_loaded?(@media)}"}
      phx-hook="Toolbar"
      phx-update="ignore"
      class="will-change-[filter] w-min	opacity-0 absolute z-20 rounded-lg select-none overflow-hidden"
      style="bottom: 0; right: 0; transform: translate(0, 0);"
    >
      <%= if Documents.has_outline?(@media) do %>
        <div
          id="toolbar-outline"
          class="bg-black p-2 overflow-auto no-scrollbar rounded-t-lg flex flex-col text-xs font-mono text-white toolbar-box slide-up"
          style="max-height: 50vh;"
        >
          <%= for p <- @media.metadata.parts do %>
            <a href={"#/page/#{p.page}"} class={"pl-#{p.level + 1}"} data-page={p.page}>
              <%= p.title %> (<%= p.page %>)
            </a>
          <% end %>
        </div>
      <% end %>
      <div
        id="toolbar-nav"
        class="bg-black drop-shadow-lg rounded-lg place-content-between space-x-2 max-w-fit flex text-xs text-white p-4"
      >
        <button
          class="flex flex-col text-center items-center"
          phx-click="show-command-palette"
          phx-target={@myself}
        >
          <.icon name="document" class="group-hover:text-gray-500 flex-shrink-0 h-6 w-6" />
          <span class="font-mono">
            Docs
          </span>
          <.keyboard>
            Ctrl-k
          </.keyboard>
        </button>

        <%= if Documents.has_outline?(@media) do %>
          <button
            phx-click={
              toggle_class(to: "#toolbar-outline", class: "slide-up")
              |> toggle_class(to: "#toolbar-outline", class: "slide-down")
            }
            class="flex flex-col text-center items-center"
            id="toolbar-toggle-outline"
          >
            <.icon
              name="clipboard-document-list"
              class="group-hover:text-gray-500 flex-shrink-0 h-6 w-6"
            />
            <span class="font-mono">
              ToC
            </span>
            <.keyboard>
              Ctrl-o
            </.keyboard>
          </button>
        <% end %>

        <%= unless is_nil(@media) do %>
          <button
            phx-click={JS.dispatch("caddishouse:resize-pdf")}
            class="flex flex-col text-center items-center"
            id="toolbar-toggle-size"
          >
            <.icon name="arrows-pointing-out" class="group-hover:text-gray-500 flex-shrink-0 h-6 w-6" />
            <span class="font-mono">
              Size
            </span>
            <.keyboard>
              Ctrl-s
            </.keyboard>
          </button>

          <div id="page-info" class="px-2 my-2 bg-white text-black flex items-center justify-middle">
            <input
              class="p-0 bg-gray-100 focus:outline-none focus:ring-0 outline-none appearance-none text-xs text-center"
              value={@media.metadata.current_page}
              type="number"
              step="1"
              min="1"
              max={@media.metadata.total_pages}
              id="current-page"
              style={"width: calc(#{integer_digits(@media.metadata.total_pages)} * 1ch + 1px)"}
            /> <span class="mx-1">of</span> <span><%= @media.metadata.total_pages %></span>
          </div>
        <% end %>

        <button
          class="flex flex-col text-center items-center"
          phx-click="show-settings"
          phx-target={@myself}
        >
          <.icon name="user" class="group-hover:text-gray-500 flex-shrink-0 h-6 w-6" />
          <span class="font-mono">
            User
          </span>
        </button>

        <button
          class="flex flex-col text-center items-center"
          phx-click="show-about"
          phx-target={@myself}
        >
          <.icon name="information-circle" class="group-hover:text-gray-500 flex-shrink-0 h-6 w-6" />
          <span class="font-mono">
            Info
          </span>
        </button>
      </div>
    </div>
    """
  end

  defp integer_digits(str), do: max(2, str |> Integer.digits() |> Enum.count())
end
