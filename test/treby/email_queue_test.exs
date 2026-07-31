defmodule Treby.EmailQueueTest do
  use Treby.DataCase, async: true

  alias Treby.{EmailQueue, Repo}
  alias Treby.EmailQueue.ScheduledEmail

  defp setup_tenant do
    {:ok, tenant} =
      Treby.Tenants.create_tenant(%{
        name: "Test Corp",
        slug: "test-#{System.unique_integer([:positive])}"
      })

    {:ok, user} =
      tenant
      |> Ecto.build_assoc(:users)
      |> Treby.Accounts.User.changeset(%{
        email: "test-#{System.unique_integer([:positive])}@test.com",
        password: "password123",
        name: "Test User",
        role: "admin"
      })
      |> Repo.insert()

    {tenant, user}
  end

  defp valid_attrs(tenant, overrides \\ %{}) do
    now = DateTime.utc_now()
    later = DateTime.add(now, 3600, :second)

    Map.merge(
      %{
        tenant_id: tenant.id,
        scheduled_at: later,
        to_address: "candidate@example.com",
        from_address: "recruiter@example.com",
        subject: "Interview Invitation",
        html_body: "<p>You're invited!</p>",
        email_type: "compose"
      },
      overrides
    )
  end

  defp create_queued(tenant, overrides \\ %{}) do
    {:ok, s} = EmailQueue.create_scheduled_email(valid_attrs(tenant, overrides))
    s
  end

  defp create_sent(tenant) do
    s = create_queued(tenant)
    {:ok, s} = EmailQueue.update_status(s, "sent")
    s
  end

  defp create_failed(tenant) do
    s = create_queued(tenant)
    {:ok, s} = EmailQueue.update_status(s, "failed", error_reason: "timeout")
    s
  end

  defp create_cancelled(tenant) do
    s = create_queued(tenant)
    Repo.update!(ScheduledEmail.changeset(s, %{status: "cancelled"}))
  end

  describe "create_scheduled_email/1" do
    test "creates a scheduled email with computed send_at" do
      {tenant, _user} = setup_tenant()
      attrs = valid_attrs(tenant)

      {:ok, scheduled} = EmailQueue.create_scheduled_email(attrs)

      assert scheduled.status == "scheduled"
      assert scheduled.to_address == "candidate@example.com"
      assert scheduled.subject == "Interview Invitation"
      assert scheduled.send_at == scheduled.scheduled_at
    end

    test "applies jitter to send_at" do
      {tenant, _user} = setup_tenant()
      attrs = valid_attrs(tenant, %{jitter_minutes: 30})

      {:ok, scheduled} = EmailQueue.create_scheduled_email(attrs)

      assert scheduled.send_at != scheduled.scheduled_at
    end

    test "validates required fields" do
      {:error, changeset} = EmailQueue.create_scheduled_email(%{})
      assert changeset.valid? == false
    end
  end

  describe "list_*" do
    test "list_queued returns scheduled emails" do
      {tenant, _user} = setup_tenant()

      queued = create_queued(tenant)
      create_sent(tenant)

      queued_ids = EmailQueue.list_queued(tenant.id) |> Enum.map(& &1.id)
      assert queued.id in queued_ids
      assert length(queued_ids) == 1
    end

    test "list_sent returns only sent emails" do
      {tenant, _user} = setup_tenant()

      create_queued(tenant)
      sent = create_sent(tenant)

      sent_ids = EmailQueue.list_sent(tenant.id) |> Enum.map(& &1.id)
      assert sent.id in sent_ids
      assert length(sent_ids) == 1
    end

    test "list_failed returns only failed emails" do
      {tenant, _user} = setup_tenant()

      failed = create_failed(tenant)

      failed_ids = EmailQueue.list_failed(tenant.id) |> Enum.map(& &1.id)
      assert failed.id in failed_ids
    end

    test "list_cancelled returns only cancelled emails" do
      {tenant, _user} = setup_tenant()

      cancelled = create_cancelled(tenant)

      cancelled_ids = EmailQueue.list_cancelled(tenant.id) |> Enum.map(& &1.id)
      assert cancelled.id in cancelled_ids
    end
  end

  describe "cancel_scheduled_email/1" do
    test "cancels a scheduled email" do
      {tenant, _user} = setup_tenant()
      scheduled = create_queued(tenant)

      {:ok, :ok} = EmailQueue.cancel_scheduled_email(scheduled)

      updated = EmailQueue.get_scheduled_email!(scheduled.id)
      assert updated.status == "cancelled"
    end
  end

  describe "edit_scheduled_email/2" do
    test "updates subject, body, and schedule" do
      {tenant, _user} = setup_tenant()
      scheduled = create_queued(tenant)

      new_time = DateTime.add(DateTime.utc_now(), 7200, :second)

      {:ok, updated} =
        EmailQueue.edit_scheduled_email(scheduled, %{
          subject: "Updated Subject",
          body: "Updated body",
          scheduled_at: new_time
        })

      assert updated.subject == "Updated Subject"
      assert updated.body == "Updated body"
    end
  end

  describe "force_send/1" do
    test "reschedules delivery (inline) — email gets sent" do
      {tenant, _user} = setup_tenant()
      scheduled = create_queued(tenant)

      {:ok, :ok} = EmailQueue.force_send(scheduled)

      updated = EmailQueue.get_scheduled_email!(scheduled.id)
      assert updated.status == "sent"
    end
  end

  describe "retry_failed/1" do
    test "resets failed email — new job sends it (inline)" do
      {tenant, _user} = setup_tenant()
      failed = create_failed(tenant)

      {:ok, :ok} = EmailQueue.retry_failed(failed)

      updated = EmailQueue.get_scheduled_email!(failed.id)
      assert updated.status == "sent"
      assert updated.error_reason == nil
    end
  end

  describe "update_status/3" do
    test "updates to sent with timestamp" do
      {tenant, _user} = setup_tenant()
      scheduled = create_queued(tenant)

      {:ok, updated} = EmailQueue.update_status(scheduled, "sent")

      assert updated.status == "sent"
      assert updated.sent_at != nil
    end

    test "updates to failed with error reason" do
      {tenant, _user} = setup_tenant()
      scheduled = create_queued(tenant)

      {:ok, updated} =
        EmailQueue.update_status(scheduled, "failed", error_reason: "Connection refused")

      assert updated.status == "failed"
      assert updated.failed_at != nil
      assert updated.error_reason == "Connection refused"
    end
  end

  describe "record_failure/3" do
    test "keeps email scheduled and increments retry_count when not final" do
      {tenant, _user} = setup_tenant()
      scheduled = create_queued(tenant)

      {:ok, updated} = EmailQueue.record_failure(scheduled, "connection refused", false)

      assert updated.status == "scheduled"
      assert updated.retry_count == 1
      assert updated.error_reason == "connection refused"
      assert is_nil(updated.failed_at)
    end

    test "marks email failed with failed_at when final" do
      {tenant, _user} = setup_tenant()
      scheduled = create_queued(tenant)

      {:ok, updated} = EmailQueue.record_failure(scheduled, "connection refused", true)

      assert updated.status == "failed"
      assert updated.retry_count == 1
      assert updated.error_reason == "connection refused"
      refute is_nil(updated.failed_at)
    end
  end

  describe "delete_scheduled_email/1" do
    test "deletes the record" do
      {tenant, _user} = setup_tenant()
      scheduled = create_queued(tenant)

      {:ok, :ok} = EmailQueue.delete_scheduled_email(scheduled)

      assert_raise Ecto.NoResultsError, fn ->
        EmailQueue.get_scheduled_email!(scheduled.id)
      end
    end
  end
end
