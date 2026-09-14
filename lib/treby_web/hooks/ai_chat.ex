defmodule TrebyWeb.Hooks.AiChat do
  @moduledoc """
  LiveView on_mount hook that exposes the current page context to the AI widget
  and relays AI PubSub messages to it.

  Sets `current_path`, `current_params` and `current_view` from the URI on every
  authenticated app page, subscribes the LiveView to the user's AI topic, and
  forwards stream/update/error messages to the `TrebyWeb.AiChatWidget` component.
  """

  import Phoenix.Component, only: [assign: 2, assign: 3]
  import Phoenix.LiveView, only: [attach_hook: 4, connected?: 1]

  alias Treby.AI.Conversations

  @widget_id "ai-chat"

  def on_mount(:default, _params, session, socket) do
    socket =
      socket
      |> assign(:current_path, nil)
      |> assign(:current_params, %{})
      |> assign(:current_view, socket.view)
      |> assign(:ai_session_token, session["ai_session_token"])
      |> attach_hook(:ai_chat_params, :handle_params, fn _params, uri, socket ->
        parsed = URI.parse(uri)

        socket =
          assign(socket, current_path: parsed.path, current_params: query_params(parsed))

        Process.put(:ai_host_assigns, socket.assigns)
        {:cont, socket}
      end)
      |> attach_hook(:ai_chat_context, :after_render, fn socket ->
        Process.put(:ai_host_assigns, socket.assigns)
        socket
      end)
      |> maybe_subscribe()
      |> attach_hook(:ai_chat_info, :handle_info, &handle_info/2)

    {:cont, socket}
  end

  defp maybe_subscribe(socket) do
    if connected?(socket) && socket.assigns[:current_user] && socket.assigns[:current_tenant] do
      topic =
        Conversations.topic(socket.assigns.current_tenant.id, socket.assigns.current_user.id)

      Phoenix.PubSub.subscribe(Treby.PubSub, topic)
    end

    socket
  end

  defp handle_info({:ai_stream, user_id, chunk}, socket)
       when user_id == socket.assigns.current_user.id do
    Phoenix.LiveView.send_update(TrebyWeb.AiChatWidget, id: @widget_id, stream_chunk: chunk)
    {:halt, socket}
  end

  defp handle_info({:ai_updated, user_id}, socket)
       when user_id == socket.assigns.current_user.id do
    Phoenix.LiveView.send_update(TrebyWeb.AiChatWidget, id: @widget_id, ai_reload: true)
    {:halt, socket}
  end

  defp handle_info({:ai_error, user_id, reason}, socket)
       when user_id == socket.assigns.current_user.id do
    Phoenix.LiveView.send_update(TrebyWeb.AiChatWidget, id: @widget_id, ai_error: reason)
    {:halt, socket}
  end

  defp handle_info(_message, socket), do: {:cont, socket}

  defp query_params(%URI{query: nil}), do: %{}
  defp query_params(%URI{query: query}), do: URI.decode_query(query)
end
