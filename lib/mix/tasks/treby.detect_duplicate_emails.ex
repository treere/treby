defmodule Mix.Tasks.Treby.DetectDuplicateEmails do
  @shortdoc "Reports active candidates sharing the same normalized email per tenant"

  @moduledoc """
  Read-only pre-migration report.

  Groups active candidates (`merged_into_id IS NULL`) by tenant and
  normalized email (`lower(trim(email))`) and prints groups with more than
  one row. Run this before applying the partial unique index migration
  `add_candidates_tenant_email_unique_active`, then resolve reported groups
  (e.g. via merge or `Candidates.auto_merge_exact_email/1`).

  Exits non-zero when duplicates are found so CI can gate the migration.
  """

  use Mix.Task

  import Ecto.Query, warn: false

  @impl Mix.Task
  def run(_args) do
    Mix.Task.run("app.start")

    groups = duplicate_groups()

    if groups == [] do
      Mix.shell().info("No duplicate active candidate emails found.")
    else
      Mix.shell().error("Found #{length(groups)} duplicate email group(s):")

      Enum.each(groups, fn %{tenant_id: tenant_id, email: email, count: count} ->
        Mix.shell().error("  tenant=#{tenant_id} email=#{email} count=#{count}")
      end)

      exit({:shutdown, 1})
    end
  end

  @doc false
  def duplicate_groups do
    Treby.Candidates.Candidate
    |> where([c], is_nil(c.merged_into_id))
    |> group_by([c], [c.tenant_id, fragment("lower(trim(?))", c.email)])
    |> having([c], count(c.id) > 1)
    |> select([c], %{
      tenant_id: c.tenant_id,
      email: fragment("lower(trim(?))", c.email),
      count: count(c.id)
    })
    |> Treby.Repo.all()
  end
end
