defmodule Treby.AI.Tools.Shared do
  @moduledoc "Tools shared by every profile (page write + domain handoff)."

  alias Treby.AI.Tools.{ProposeFormFill, Handoff}

  @tools [ProposeFormFill, Handoff]

  def all, do: @tools
end
