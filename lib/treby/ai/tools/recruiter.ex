defmodule Treby.AI.Tools.Recruiter do
  @moduledoc "Recruiting tools: jobs, candidates, applications, stages, notes."

  alias Treby.AI.Tools.{
    CreateJob,
    UpdateJob,
    DeleteJob,
    ListJobs,
    CreateCandidate,
    ListCandidates,
    GetCandidate,
    UpdateCandidate,
    CreateApplication,
    MoveApplication,
    AddNote
  }

  @tools [
    ListJobs,
    CreateJob,
    UpdateJob,
    DeleteJob,
    CreateCandidate,
    ListCandidates,
    GetCandidate,
    UpdateCandidate,
    CreateApplication,
    MoveApplication,
    AddNote
  ]

  def all, do: @tools
end
