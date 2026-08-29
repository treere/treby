defmodule Treby.Calendar.MeetingProvider do
  @moduledoc """
  Behaviour for meeting providers that generate video conference links.

  Meeting links are pure URLs (e.g. Jitsi) or a byproduct of calendar event
  creation (e.g. Google Meet). Providers that only generate URLs implement
  this behaviour.
  """

  @doc "Generates a video conference link for a given context (e.g. tenant slug)."
  @callback create_meeting_link(context :: map()) :: {:ok, String.t()} | {:error, term()}
end
