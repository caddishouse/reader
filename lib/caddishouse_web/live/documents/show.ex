defmodule CaddishouseWeb.Live.Documents.Show do
  @moduledoc false
  use CaddishouseWeb, :live_view
  alias Caddishouse.Documents
  alias CaddishouseWeb.Live.Components
  alias CaddishouseWeb.Live.Components.Toasts

  @impl true
  def mount(%{"id" => id}, _, socket) do
    media = Documents.get_by_id!(socket.assigns.current_user, id)
    CaddishouseWeb.Endpoint.subscribe("user_socket:#{socket.assigns.current_user.id}")

    {:ok, assign_socket(media, socket)}
  end

  @doc """
  Displays most recently viewed document if user is logged-in.
  Otherwise shows default about PDF.
  """
  @impl true
  def mount(%{}, _, socket) do
    current_user = socket.assigns.current_user

    if current_user do
      CaddishouseWeb.Endpoint.subscribe("user_socket:#{socket.assigns.current_user.id}")
    end

    with false <- is_nil(current_user),
         [media] <- Documents.recently_viewed(current_user, 1) do
      {:ok, assign_socket(media, socket)}
    else
      _ ->
        # TODO Pull default media from seed?
        {:ok, assign(socket, media: nil)}
    end
  end

  defp assign_socket(media, socket) do
    {:ok, media_url} = Documents.get_media_url(media)

    socket
    |> assign(media: media, media_url: media_url)
  end

  @impl true
  def handle_info(%{event: "media_imported", payload: media_id}, socket) do
    media =
      Documents.get_by_id!(
        socket.assigns.current_user,
        media_id
      )

    Toasts.info("""
      Your document is ready to be read!<br/>
      <a class="font-bold underline" href="/media/#{media_id}">#{media.name}</a>
    """)

    {:noreply, socket}
  end

  @impl true
  def handle_info(%{event: "media_not_imported", payload: media_name}, socket) do
    Toasts.error("""
      Your document <strong>#{media_name}</strong> was unable to be imported. The error has been logged and will be looked at.
    """)

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "document-loaded",
        %{"outline" => outline, "totalPages" => total_pages},
        socket
      ) do
    Documents.load_metadata(
      socket.assigns.media,
      %{
        "total_pages" => total_pages,
        "parts" => outline
      }
    )
    |> case do
      {:ok, media} ->
        {:noreply, assign(socket, media: media)}

      {:error, _error} ->
        Toasts.error("""
        There was an error loading information about your document. Your current page may not be saved. The error has been logged and will be looked at.
        """)

        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("update-current-page", %{"pageNumber" => page_number}, socket) do
    Documents.update_current_page(socket.assigns.media, page_number)
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-row h-full">
      <.live_component
        module={Components.Toolbar}
        id="toolbar"
        current_user={@current_user}
        media={@media}
      />
      <%= if @media do %>
        <div class="flex flex-col flex-1 relative h-full">
          <div
            id="document-viewer"
            phx-hook="PDFViewer"
            class="absolute z-10 h-full w-full overflow-scroll"
            data-current-page={if is_nil(@media.metadata), do: 1, else: @media.metadata.current_page}
            data-metadata-loaded={Documents.metadata_loaded?(@media)}
            data-media-url={@media_url}
          >
            <div phx-update="ignore" id="viewer" class="absolute h-full w-full pdfViewer"></div>
          </div>
        </div>
      <% end %>
    </div>
    """
  end
end
