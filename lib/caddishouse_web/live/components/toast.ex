defmodule CaddishouseWeb.Live.Components.Toasts do
  @moduledoc """
  Influenced by work on https://github.com/madscatter/lv_toast/
  """
  use CaddishouseWeb, :live_component
  @id "toast"

  defmodule Toast do
    # ms
    defstruct id: nil, content: "", kind: :info, duration: 60_000

    defp build(content, kind, duration) do
      %Toast{
        id: System.monotonic_time() |> Integer.to_string(),
        content: content,
        kind: kind,
        duration: duration
      }
    end

    def info(content, duration \\ nil) do
      build(content, :info, duration)
    end

    def error(content, duration \\ nil) do
      build(content, :error, duration)
    end
  end

  def info(content) do
    send_update(__MODULE__, id: @id, toast: Toast.info(content))
  end

  def error(content) do
    send_update(__MODULE__, id: @id, toast: Toast.error(content))
  end

  @impl true
  def update(%{toast: %Toast{} = toast}, socket) do
    socket =
      update(socket, :toasts, fn toasts ->
        [toast | toasts]
      end)

    {:ok, socket}
  end

  @impl true
  def update(_, socket) do
    socket = assign_new(socket, :toasts, fn -> [] end)

    {:ok, socket}
  end

  @impl true
  def handle_event("add", toast, socket) do
    {:noreply, update(socket, :toasts, fn toasts -> [toast | toasts] end)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="fixed top-1 right-1 space-y-3 z-50">
      <%= for toast <- @toasts do %>
        <.toast toast={toast} />
      <% end %>
    </div>
    """
  end

  defp toast(%{toast: %{kind: :error}} = assigns) do
    ~H"""
    <div
      id={"toast-#{@toast.id}"}
      phx-update="ignore"
      class="rounded-md bg-red-50 p-4 w-96 fade-in-scale "
      data-duration={@toast.duration}
      phx-click={
        JS.remove_class("fade-in-scale", to: "#toast-" <> @toast.id)
        |> hide("#toast-" <> @toast.id)
      }
      phx-hook="Flash"
    >
      <div class="flex justify-between items-center space-x-3 text-red-700">
        <.icon name="exclamation-circle" class="w-5 w-5" />
        <p class="flex-1 text-sm font-medium" role="alert">
          <%= raw(@toast.content) %>
        </p>
        <button
          type="button"
          class="inline-flex bg-red-50 rounded-md p-1.5 text-red-500 hover:bg-red-100 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-offset-red-50 focus:ring-red-600"
        >
          <.icon name="x-mark" class="w-4 h-4" />
        </button>
      </div>
    </div>
    """
  end

  defp toast(%{toast: %{kind: :info}} = assigns) do
    ~H"""
    <div
      id={"toast-#{@toast.id}"}
      phx-update="ignore"
      class="rounded-md bg-green-50 p-4 w-96 fade-in-scale "
      phx-click={
        JS.remove_class("fade-in-scale", to: "#toast-" <> @toast.id)
        |> hide("#toast-" <> @toast.id)
      }
      phx-hook="Flash"
    >
      <div class="flex justify-between items-center space-x-3 text-green-700">
        <.icon name="check-circle" class="w-5 w-5" />
        <p class="flex-1 text-sm font-medium" role="alert">
          <%= raw(@toast.content) %>
        </p>
        <button
          type="button"
          class="inline-flex bg-green-50 rounded-md p-1.5 text-green-500 hover:bg-green-100 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-offset-green-50 focus:ring-green-600"
        >
          <.icon name="x-mark" class="w-4 h-4" />
        </button>
      </div>
    </div>
    """
  end
end
