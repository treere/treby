defmodule Treby.Calendar.Providers.Jitsi do
  @moduledoc """
  Jitsi meeting provider: generates meeting links as pure URLs.

  Rooms are unguessable (UUID) and prefixed with the tenant slug for clarity.
  """

  @behaviour Treby.Calendar.MeetingProvider

  @base_url "https://meet.jit.si"

  @impl true
  def create_meeting_link(%{tenant_slug: tenant_slug}) do
    room = "treby-#{tenant_slug}-#{Ecto.UUID.generate()}"
    {:ok, "#{@base_url}/#{room}"}
  end
end
