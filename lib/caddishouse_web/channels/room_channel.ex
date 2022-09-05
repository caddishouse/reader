defmodule Caddishouseweb.RoomChannel do
  use Phoenix.Channel

  def join("room:" <> user_id, _params, socket) do
    if user_id == socket.assigns.current_user.id do
      {:ok, socket}
    else
      {:error, :not_authorized}
    end
  end
end
