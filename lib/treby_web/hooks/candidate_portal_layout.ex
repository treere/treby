defmodule TrebyWeb.Hooks.CandidatePortalLayout do
  @moduledoc """
  On-mount hook to set the candidate portal layout.
  """

  def on_mount(:set_portal_layout, _params, _session, socket) do
    {:cont, socket |> Phoenix.Controller.put_layout(html: {TrebyWeb.Layouts, :candidate_portal})}
  end
end
