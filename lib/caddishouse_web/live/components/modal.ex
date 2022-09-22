defmodule CaddishouseWeb.Live.Components.Modal do
  @moduledoc false
  use CaddishouseWeb, :live_component

  def show(module, attrs) do
    send_update(__MODULE__, id: "modal", show: Enum.into(attrs, %{module: module}))
  end

  def hide do
    send_update(__MODULE__, id: "modal", show: nil)
  end

  def show_modal(js \\ %JS{}, id) when is_binary(id) do
    js
    |> JS.show(
      to: "##{id}",
      display: "inline-block",
      transition: {"ease-out duration-300", "opacity-0", "opacity-100"}
    )
    |> JS.show(
      to: "##{id}-container",
      display: "inline-block",
      transition:
        {"ease-out duration-300", "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
    |> js_exec("##{id}-confirm", "focus", [])
  end

  def hide_modal(js \\ %JS{}, id, target) do
    js
    |> JS.remove_class("fade-in", to: "##{id}")
    |> JS.hide(
      to: "##{id}",
      transition: {"ease-in duration-200", "opacity-100", "opacity-0"}
    )
    |> JS.hide(
      to: "##{id}-container",
      transition:
        {"ease-in duration-200", "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
    |> JS.push("hide", target: target)
  end

  @impl true
  def handle_event("keydown", %{"key" => "Escape"}, socket) do
    hide()
    {:noreply, socket}
  end

  @impl true
  def handle_event("hide", _, socket) do
    hide()
    {:noreply, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket = assign(socket, assigns)

    show =
      case assigns[:show] do
        %{module: _module} = show ->
          show

        nil ->
          nil
      end

    {:ok, assign(socket, show: show)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <%= if @show do %>
        <div id={@id} class={"#{if @show, do: "fade-in", else: 'hidden'} z-30 relative"}>
          <div
            class="fixed inset-0 z-30 bg-gray-500 bg-opacity-75 transition-opacity"
            aria-hidden="true"
          >
          </div>
          <.focus_wrap id={"#{@id}-focus-wrap"}>
            <div
              class="fixed inset-0 z-40 overflow-y-auto p-4 sm:p-6 md:p-20"
              phx-target={@myself}
              phx-click={hide_modal(@id, @myself)}
            >
              <div
                id={"#{@id}-container"}
                class={
                  "#{if @show, do: "fade-in", else: "hidden"} mx-auto max-w-2xl transform divide-y divide-gray-100 overflow-hidden rounded-xl bg-white shadow-2xl ring-1 ring-black ring-opacity-5 transition-all opacity-100 scale-100"
                }
                aria-labelledby={"#{@id}-title"}
                aria-describedby={"#{@id}-description"}
                role="dialog"
                phx-click={JS.dispatch("click", bubbles: false)}
                aria-modal="true"
                phx-window-keydown={hide_modal(@id, @myself)}
                phx-key="escape"
                phx-target={@myself}
              >
                <.live_component module={@show.module} id={@id} current_user={@current_user} />
              </div>
            </div>
          </.focus_wrap>
        </div>
      <% end %>
    </div>
    """
  end
end
