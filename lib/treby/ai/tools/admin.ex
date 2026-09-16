defmodule Treby.AI.Tools.Admin do
  @moduledoc "Workspace admin tools."

  alias Treby.AI.Tools.{
    AddMember,
    RemoveMember,
    AddPipelineStage,
    ImportCsv,
    UpdateSettings
  }

  @tools [
    AddMember,
    RemoveMember,
    AddPipelineStage,
    ImportCsv,
    UpdateSettings
  ]

  def all, do: @tools
end
