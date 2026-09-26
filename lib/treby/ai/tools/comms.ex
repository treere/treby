defmodule Treby.AI.Tools.Comms do
  @moduledoc "Communication tools."

  alias Treby.AI.Tools.{
    CancelScheduledMessage,
    CreateEmailTemplate,
    DeleteEmailTemplate,
    InviteMember,
    ListEmailTemplates,
    ListScheduledMessages,
    RescheduleScheduledMessage,
    RetryScheduledMessage,
    ScheduleMessage,
    SendMessage,
    UpdateEmailTemplate
  }

  @tools [
    SendMessage,
    ScheduleMessage,
    ListScheduledMessages,
    CancelScheduledMessage,
    RescheduleScheduledMessage,
    RetryScheduledMessage,
    ListEmailTemplates,
    CreateEmailTemplate,
    UpdateEmailTemplate,
    DeleteEmailTemplate,
    InviteMember
  ]

  def all, do: @tools
end
