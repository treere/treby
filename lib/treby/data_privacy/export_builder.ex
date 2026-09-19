defmodule Treby.DataPrivacy.ExportBuilder do
  import Ecto.Query, warn: false
  alias Treby.Repo

  @doc """
  Build export data for tenant or user scope.

  Returns {export_map, s3_keys} where s3_keys are tenant-scoped S3 keys to bundle.
  """
  def build(tenant_id, %Treby.DataPrivacy.DataPrivacyRequest{scope: "tenant"}) do
    build_tenant(tenant_id)
  end

  def build(tenant_id, %Treby.DataPrivacy.DataPrivacyRequest{scope: "user", requester_id: user_id}) do
    build_user(tenant_id, user_id)
  end

  defp build_tenant(tenant_id) do
    tenant = Treby.Tenants.get_tenant!(tenant_id)

    users =
      Treby.Accounts.list_users(tenant_id)
      |> Enum.map(&sanitize_user/1)

    candidates =
      Repo.all(from c in Treby.Candidates.Candidate, where: c.tenant_id == ^tenant_id)
      |> Enum.map(&sanitize_candidate/1)

    jobs =
      Repo.all(from j in Treby.Jobs.Job, where: j.tenant_id == ^tenant_id)
      |> Enum.map(&sanitize_job/1)

    applications =
      Repo.all(from a in Treby.Pipeline.Application, where: a.tenant_id == ^tenant_id)
      |> Enum.map(&sanitize_application/1)

    notes =
      Repo.all(
        from n in Treby.Notes.Note,
          join: a in Treby.Pipeline.Application,
          on: n.application_id == a.id,
          where: a.tenant_id == ^tenant_id,
          select: n
      )
      |> Enum.map(&sanitize_note/1)

    interviews = fetch_optional(:interviews, tenant_id)
    scorecards = fetch_optional(:scorecards, tenant_id)
    messages = fetch_optional(:messages, tenant_id)

    s3_keys =
      (Enum.map(applications, & &1[:resume_url]) ++
         Enum.map(users, fn _ -> nil end))
      |> Enum.filter(& &1)
      |> Enum.filter(&String.starts_with?(&1, "#{tenant_id}/"))

    export = %{
      tenant: sanitize_tenant(tenant),
      users: users,
      candidates: candidates,
      jobs: jobs,
      applications: applications,
      notes: notes,
      interviews: interviews,
      scorecards: scorecards,
      messages: messages,
      exported_at: DateTime.utc_now() |> DateTime.to_iso8601()
    }

    {export, s3_keys}
  end

  defp build_user(_tenant_id, user_id) do
    user = Repo.get!(Treby.Accounts.User, user_id)

    notes =
      Repo.all(from n in Treby.Notes.Note, where: n.author_id == ^user_id)
      |> Enum.map(&sanitize_note/1)

    scorecards = []
    interviews = []

    export = %{
      user: sanitize_user(user),
      notes: notes,
      scorecards: scorecards,
      interviews: interviews,
      exported_at: DateTime.utc_now() |> DateTime.to_iso8601()
    }

    {export, []}
  end

  defp fetch_optional(:interviews, tenant_id) do
    if Code.ensure_loaded?(Treby.Interviews.InterviewEvent) do
      Repo.all(
        from e in Treby.Interviews.InterviewEvent,
          join: a in Treby.Pipeline.Application,
          on: e.application_id == a.id,
          where: a.tenant_id == ^tenant_id,
          select: e
      )
      |> Enum.map(&sanitize_interview/1)
    else
      []
    end
  rescue
    _ -> []
  end

  defp fetch_optional(:scorecards, tenant_id) do
    Repo.all(
      from s in Treby.Scorecards.Scorecard,
        join: a in Treby.Pipeline.Application,
        on: s.application_id == a.id,
        where: a.tenant_id == ^tenant_id,
        select: s
    )
    |> Enum.map(&sanitize_scorecard/1)
  rescue
    _ -> []
  end

  defp fetch_optional(:messages, tenant_id) do
    Repo.all(from m in Treby.ScheduledMessages.ScheduledMessage, where: m.tenant_id == ^tenant_id)
    |> Enum.map(&sanitize_message/1)
  rescue
    _ -> []
  end

  defp sanitize_user(u) do
    %{
      id: u.id,
      email: u.email,
      name: u.name,
      role: u.role,
      locale: u.locale,
      timezone: u.timezone,
      inserted_at: u.inserted_at,
      updated_at: u.updated_at
    }
  end

  defp sanitize_candidate(c) do
    %{
      id: c.id,
      name: c.name,
      email: c.email,
      phone: c.phone,
      linkedin_url: c.linkedin_url,
      custom_fields: c.custom_fields,
      inserted_at: c.inserted_at,
      updated_at: c.updated_at
    }
  end

  defp sanitize_job(j) do
    %{
      id: j.id,
      title: j.title,
      description: j.description,
      status: j.status,
      location: j.location,
      employment_type: j.employment_type,
      inserted_at: j.inserted_at
    }
  end

  defp sanitize_application(a) do
    %{
      id: a.id,
      candidate_id: a.candidate_id,
      job_id: a.job_id,
      pipeline_stage_id: a.pipeline_stage_id,
      resume_url: a.resume_url,
      anagrafica: a.anagrafica,
      applied_at: a.applied_at,
      inserted_at: a.inserted_at
    }
  end

  defp sanitize_note(n) do
    %{
      id: n.id,
      application_id: n.application_id,
      content: n.content,
      type: n.type,
      rating: n.rating,
      inserted_at: n.inserted_at
    }
  end

  defp sanitize_interview(i) do
    %{id: i.id, application_id: i.application_id, inserted_at: i.inserted_at}
  rescue
    _ -> %{id: i.id}
  end

  defp sanitize_scorecard(s) do
    %{id: s.id, application_id: s.application_id, inserted_at: s.inserted_at}
  rescue
    _ -> %{id: s.id}
  end

  defp sanitize_message(m) do
    %{id: m.id, status: m.status, inserted_at: m.inserted_at}
  rescue
    _ -> %{id: m.id}
  end

  defp sanitize_tenant(t) do
    %{id: t.id, name: t.name, slug: t.slug, timezone: t.timezone}
  end
end
