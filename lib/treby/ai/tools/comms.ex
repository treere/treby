defmodule Treby.AI.Tools.Comms do
  @moduledoc "Communication tools."

  alias Treby.AI.Tools.{
    SendMessage,
    ScheduleMessage,
    CreateEmailTemplate,
    InviteMember
  }

  @tools [
    SendMessage,
    ScheduleMessage,
    CreateEmailTemplate,
    InviteMember
  ]

  def all, do: @tools
end
