defmodule Treby.DataPrivacy.Anonymizer do
  import Ecto.Query, warn: false
  alias Treby.Repo

  @doc "Anonymize single candidate, idempotent."
  def anonymize_candidate(%Treby.Candidates.Candidate{} = candidate) do
    if anonymized?(candidate) do
      {:ok, candidate}
    else
      short = String.slice(candidate.id, 0, 8)

      candidate
      |> Ecto.Changeset.change(%{
        name: "Deleted Candidate #{short}",
        email: "deleted+#{candidate.id}@deleted.local",
        phone: nil,
        linkedin_url: nil,
        custom_fields: %{},
        notification_preferences: %{}
      })
      |> Repo.update()
    end
  end

  def anonymized?(%Treby.Candidates.Candidate{email: email}) when is_binary(email) do
    String.starts_with?(email, "deleted+")
  end

  def anonymized?(_), do: false

  @doc "Anonymize user, idempotent."
  def anonymize_user(%Treby.Accounts.User{} = user) do
    if String.starts_with?(user.email || "", "deleted+") do
      {:ok, user}
    else
      user
      |> Ecto.Changeset.change(%{
        name: "Deleted User #{String.slice(user.id, 0, 8)}",
        email: "deleted+#{user.id}@deleted.local",
        password_hash: Bcrypt.hash_pwd_salt(Ecto.UUID.generate())
      })
      |> Repo.update()
    end
  end

  def purge_s3_objects(tenant_id, s3_keys) when is_list(s3_keys) do
    Enum.each(s3_keys, fn key ->
      try do
        Treby.Uploads.delete_file(tenant_id, key)
      rescue
        _ -> :ok
      end
    end)
  end

  def anonymize_tenant_candidates(tenant_id) do
    from(c in Treby.Candidates.Candidate, where: c.tenant_id == ^tenant_id)
    |> Repo.all()
    |> Enum.chunk_every(100)
    |> Enum.each(fn batch ->
      Enum.each(batch, fn candidate ->
        {:ok, _} = anonymize_candidate(candidate)
      end)
    end)

    # Clear resume_url on applications + delete S3 resumes
    from(a in Treby.Pipeline.Application,
      where: a.tenant_id == ^tenant_id and not is_nil(a.resume_url)
    )
    |> Repo.all()
    |> Enum.each(fn app ->
      if app.resume_url do
        try do
          Treby.Uploads.delete_file(tenant_id, app.resume_url)
        rescue
          _ -> :ok
        end
      end

      app
      |> Ecto.Changeset.change(%{resume_url: nil, anagrafica: %{}})
      |> Repo.update()
    end)
  end

  def anonymize_tenant_users(tenant_id) do
    users = Treby.Accounts.list_users(tenant_id)

    Enum.each(users, fn user ->
      {:ok, _} = anonymize_user(user)
    end)

    # Remove memberships after anonymizing
    from(m in Treby.Memberships.Membership, where: m.tenant_id == ^tenant_id)
    |> Repo.delete_all()
  end

  def anonymize_audit_metadata(tenant_id, erased_ids) when is_list(erased_ids) do
    # Scrub PII from audit metadata for erased subjects
    from(a in Treby.Audit.AuditEvent,
      where: a.tenant_id == ^tenant_id and a.actor_id in ^erased_ids
    )
    |> Repo.all()
    |> Enum.each(fn event ->
      scrubbed = scrub_metadata(event.metadata, erased_ids)
      event |> Ecto.Changeset.change(%{metadata: scrubbed}) |> Repo.update()
    end)

    from(a in Treby.Audit.AuditEvent,
      where: a.tenant_id == ^tenant_id and a.entity_id in ^erased_ids
    )
    |> Repo.all()
    |> Enum.each(fn event ->
      scrubbed = scrub_metadata(event.metadata, erased_ids)
      event |> Ecto.Changeset.change(%{metadata: scrubbed}) |> Repo.update()
    end)
  end

  defp scrub_metadata(nil, _), do: %{}

  defp scrub_metadata(metadata, _erased_ids) when is_map(metadata) do
    metadata
    |> Enum.map(fn {k, v} ->
      key = to_string(k) |> String.downcase()

      if String.contains?(key, "email") or String.contains?(key, "name") do
        {k, "[redacted]"}
      else
        {k, v}
      end
    end)
    |> Map.new()
  end

  defp scrub_metadata(other, _), do: other
end
