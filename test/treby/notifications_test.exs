defmodule Treby.NotificationsTest do
  use Treby.DataCase, async: true

  import Swoosh.TestAssertions

  alias Treby.{Tenants, Repo, Notifications}
  alias Treby.Accounts.User
  alias Treby.Candidates.Candidate
  alias Treby.Jobs.Job
  alias Treby.Pipeline.{Application, PipelineStage}
  alias Treby.Notifications.Email

  defp setup_tenant_with_admin do
    {:ok, tenant} =
      Tenants.create_tenant(%{
        name: "Notification Test Corp",
        slug: "notif-test-#{System.unique_integer([:positive])}"
      })

    {:ok, user} =
      tenant
      |> Ecto.build_assoc(:users)
      |> User.changeset(%{
        email: "admin-#{System.unique_integer([:positive])}@test.com",
        password: "password123",
        name: "Admin User",
        role: "admin"
      })
      |> Repo.insert()

    {tenant, user}
  end

  defp setup_tenant_with_non_admin do
    {:ok, tenant} =
      Tenants.create_tenant(%{
        name: "Non-Admin Corp",
        slug: "nonadmin-test-#{System.unique_integer([:positive])}"
      })

    {:ok, _user} =
      tenant
      |> Ecto.build_assoc(:users)
      |> User.changeset(%{
        email: "member-#{System.unique_integer([:positive])}@test.com",
        password: "password123",
        name: "Member User",
        role: "member"
      })
      |> Repo.insert()

    tenant
  end

  defp setup_job(tenant, stage_type \\ "hired") do
    pipeline_id = Treby.Pipeline.default_pipeline_id(tenant.id)
    pipeline = Repo.get!(Treby.Pipeline.Pipeline, pipeline_id)

    {:ok, stage} =
      pipeline
      |> Ecto.build_assoc(:pipeline_stages)
      |> PipelineStage.changeset(%{
        name: String.capitalize(stage_type),
        position: 0,
        stage_type: stage_type
      })
      |> Repo.insert()

    {:ok, job} =
      tenant
      |> Ecto.build_assoc(:jobs)
      |> Job.changeset(%{
        title: "Software Engineer",
        description: "Build things",
        pipeline_id: pipeline_id
      })
      |> Repo.insert()

    {job, stage}
  end

  defp setup_candidate(tenant, email) do
    {:ok, candidate} =
      tenant
      |> Ecto.build_assoc(:candidates)
      |> Candidate.changeset(%{
        name: "Test Candidate",
        email: email
      })
      |> Repo.insert()

    candidate
  end

  defp setup_application(tenant, candidate, job, stage) do
    {:ok, application} =
      %Application{}
      |> Application.changeset(%{
        candidate_id: candidate.id,
        job_id: job.id,
        pipeline_stage_id: stage.id,
        applied_at: DateTime.utc_now(),
        tenant_id: tenant.id
      })
      |> Repo.insert()

    application
  end

  defp setup_email_template(tenant_id, stage_type \\ "hired") do
    {:ok, template} =
      Treby.EmailTemplates.upsert_email_template(%{
        "tenant_id" => tenant_id,
        "name" => "#{stage_type} Notification",
        "subject" => "You've been #{stage_type} for {job_title}",
        "body" => "Hi {candidate_name}, you've been #{stage_type} for {job_title} at {company_name}.",
        "stage_type" => stage_type,
        "is_active" => true
      })

    template
  end

  describe "notification_preferences/1" do
    test "returns defaults when no preferences are set" do
      {tenant, _user} = setup_tenant_with_admin()
      prefs = Notifications.notification_preferences(tenant)

      assert prefs["stage_change_candidate"] == true
      assert prefs["new_application_candidate"] == true
      assert prefs["new_application_team"] == true
    end

    test "merges stored preferences with defaults" do
      {tenant, _user} = setup_tenant_with_admin()

      {:ok, _} =
        Notifications.set_notification_preference(tenant, "stage_change_candidate", false)

      tenant = Repo.get!(Tenants.Tenant, tenant.id)
      prefs = Notifications.notification_preferences(tenant)

      assert prefs["stage_change_candidate"] == false
      assert prefs["new_application_candidate"] == true
      assert prefs["new_application_team"] == true
    end
  end

  describe "notification_preferences_enabled?/2" do
    test "returns true when preference is enabled" do
      {tenant, _user} = setup_tenant_with_admin()
      assert Notifications.notification_preferences_enabled?(tenant, "new_application_team") == true
    end

    test "returns false when preference is disabled" do
      {tenant, _user} = setup_tenant_with_admin()
      {:ok, _} = Notifications.set_notification_preference(tenant, "new_application_team", false)

      tenant = Repo.get!(Tenants.Tenant, tenant.id)
      assert Notifications.notification_preferences_enabled?(tenant, "new_application_team") == false
    end
  end

  describe "set_notification_preference/3" do
    test "persists the preference change" do
      {tenant, _user} = setup_tenant_with_admin()
      assert {:ok, _} = Notifications.set_notification_preference(tenant, "stage_change_candidate", false)

      tenant = Repo.get!(Tenants.Tenant, tenant.id)
      assert Notifications.notification_preferences_enabled?(tenant, "stage_change_candidate") == false
    end

    test "only affects the specified key" do
      {tenant, _user} = setup_tenant_with_admin()
      {:ok, _} = Notifications.set_notification_preference(tenant, "stage_change_candidate", false)

      tenant = Repo.get!(Tenants.Tenant, tenant.id)
      assert Notifications.notification_preferences_enabled?(tenant, "new_application_candidate") == true
      assert Notifications.notification_preferences_enabled?(tenant, "new_application_team") == true
    end
  end

  describe "notify_stage_change/2" do
    test "sends email when template exists and preference enabled" do
      {tenant, _user} = setup_tenant_with_admin()
      {job, stage} = setup_job(tenant)
      candidate = setup_candidate(tenant, "stage-change@test.com")
      application = setup_application(tenant, candidate, job, stage)

      setup_email_template(tenant.id, "hired")

      assert :ok = Notifications.notify_stage_change(application, nil)

      assert_email_sent(
        subject: "You've been hired for Software Engineer",
        to: [{"", "stage-change@test.com"}]
      )
    end

    test "does not send email when preference is disabled" do
      {tenant, _user} = setup_tenant_with_admin()
      {:ok, _} = Notifications.set_notification_preference(tenant, "stage_change_candidate", false)
      tenant = Repo.get!(Tenants.Tenant, tenant.id)

      {job, stage} = setup_job(tenant)
      candidate = setup_candidate(tenant, "no-send@test.com")
      application = setup_application(tenant, candidate, job, stage)

      setup_email_template(tenant.id, "hired")

      assert :ok = Notifications.notify_stage_change(application, nil)

      assert_no_email_sent()
    end

    test "does not crash when no template exists" do
      {tenant, _user} = setup_tenant_with_admin()
      {job, stage} = setup_job(tenant)
      candidate = setup_candidate(tenant, "no-template@test.com")
      application = setup_application(tenant, candidate, job, stage)

      assert :ok = Notifications.notify_stage_change(application, nil)

      assert_no_email_sent()
    end

    test "returns :ok even when email delivery fails" do
      {tenant, _user} = setup_tenant_with_admin()
      {job, stage} = setup_job(tenant)
      candidate = setup_candidate(tenant, "fail@test.com")
      application = setup_application(tenant, candidate, job, stage)

      setup_email_template(tenant.id, "hired")

      # Configure mailer to fail
      original_config = Elixir.Application.get_env(:treby, Treby.Mailer)
      Elixir.Application.put_env(:treby, Treby.Mailer, adapter: Swoosh.Adapters.Test, api_key: "fake")

      try do
        assert :ok = Notifications.notify_stage_change(application, nil)
      after
        Elixir.Application.put_env(:treby, Treby.Mailer, original_config)
      end
    end
  end

  describe "notify_new_application_candidate/1" do
    test "sends confirmation email to candidate" do
      {tenant, _user} = setup_tenant_with_admin()
      {job, stage} = setup_job(tenant)
      candidate = setup_candidate(tenant, "confirm@test.com")
      application = setup_application(tenant, candidate, job, stage)

      assert :ok = Notifications.notify_new_application_candidate(application)

      assert_email_sent(
        subject: "Application Received - Software Engineer",
        to: [{"", "confirm@test.com"}]
      )
    end

    test "does not send when preference disabled" do
      {tenant, _user} = setup_tenant_with_admin()
      {:ok, _} = Notifications.set_notification_preference(tenant, "new_application_candidate", false)
      tenant = Repo.get!(Tenants.Tenant, tenant.id)

      {job, stage} = setup_job(tenant)
      candidate = setup_candidate(tenant, "no-confirm@test.com")
      application = setup_application(tenant, candidate, job, stage)

      assert :ok = Notifications.notify_new_application_candidate(application)

      assert_no_email_sent()
    end

    test "returns :ok even when email delivery fails" do
      {tenant, _user} = setup_tenant_with_admin()
      {job, stage} = setup_job(tenant)
      candidate = setup_candidate(tenant, "fail-confirm@test.com")
      application = setup_application(tenant, candidate, job, stage)

      original_config = Elixir.Application.get_env(:treby, Treby.Mailer)
      Elixir.Application.put_env(:treby, Treby.Mailer, adapter: Swoosh.Adapters.Test, api_key: "fake")

      try do
        assert :ok = Notifications.notify_new_application_candidate(application)
      after
        Elixir.Application.put_env(:treby, Treby.Mailer, original_config)
      end
    end
  end

  describe "notify_team_new_application/1" do
    test "sends alert to all admin users" do
      {tenant, admin} = setup_tenant_with_admin()
      {job, stage} = setup_job(tenant)
      candidate = setup_candidate(tenant, "team-alert@test.com")
      application = setup_application(tenant, candidate, job, stage)

      assert :ok = Notifications.notify_team_new_application(application)

      assert_email_sent(
        subject: "New Application: Test Candidate for Software Engineer",
        to: [{"", admin.email}]
      )
    end

    test "does not send to non-admin users from different tenant" do
      {tenant, admin} = setup_tenant_with_admin()
      _other_tenant = setup_tenant_with_non_admin()

      {job, stage} = setup_job(tenant)
      candidate = setup_candidate(tenant, "team-member@test.com")
      application = setup_application(tenant, candidate, job, stage)

      assert :ok = Notifications.notify_team_new_application(application)

      # Should only send to the admin of the correct tenant
      assert_email_sent(
        to: [{"", admin.email}]
      )
    end

    test "does not send when preference disabled" do
      {tenant, _admin} = setup_tenant_with_admin()
      {:ok, _} = Notifications.set_notification_preference(tenant, "new_application_team", false)
      tenant = Repo.get!(Tenants.Tenant, tenant.id)

      {job, stage} = setup_job(tenant)
      candidate = setup_candidate(tenant, "no-team@test.com")
      application = setup_application(tenant, candidate, job, stage)

      assert :ok = Notifications.notify_team_new_application(application)

      assert_no_email_sent()
    end

    test "returns :ok even when email delivery fails" do
      {tenant, _admin} = setup_tenant_with_admin()
      {job, stage} = setup_job(tenant)
      candidate = setup_candidate(tenant, "fail-team@test.com")
      application = setup_application(tenant, candidate, job, stage)

      original_config = Elixir.Application.get_env(:treby, Treby.Mailer)
      Elixir.Application.put_env(:treby, Treby.Mailer, adapter: Swoosh.Adapters.Test, api_key: "fake")

      try do
        assert :ok = Notifications.notify_team_new_application(application)
      after
        Elixir.Application.put_env(:treby, Treby.Mailer, original_config)
      end
    end
  end

  describe "Email.new_application_confirmation/3" do
    test "builds correct email with assigns" do
      {tenant, _user} = setup_tenant_with_admin()
      {job, _stage} = setup_job(tenant)
      candidate = setup_candidate(tenant, "email-test@test.com")

      assigns = %{
        candidate_name: candidate.name,
        job_title: job.title,
        company_name: tenant.name
      }

      email = Email.new_application_confirmation(candidate, job, assigns)

      assert email.to == [{"", "email-test@test.com"}]
      assert email.subject == "Application Received - Software Engineer"
      assert email.html_body =~ "Thank you for applying"
      assert email.html_body =~ candidate.name
      assert email.html_body =~ job.title
      assert email.text_body =~ "Thank you for applying"
    end

    test "uses defaults when assigns are empty" do
      {tenant, _user} = setup_tenant_with_admin()
      {job, _stage} = setup_job(tenant)
      candidate = setup_candidate(tenant, "defaults@test.com")

      email = Email.new_application_confirmation(candidate, job)

      assert email.html_body =~ candidate.name
      assert email.html_body =~ job.title
    end
  end

  describe "Email.new_application_team_alert/4" do
    test "builds correct email with assigns" do
      {tenant, admin} = setup_tenant_with_admin()
      {job, _stage} = setup_job(tenant)
      candidate = setup_candidate(tenant, "team-email@test.com")

      assigns = %{
        candidate_name: candidate.name,
        job_title: job.title,
        company_name: tenant.name,
        admin_name: admin.name
      }

      email = Email.new_application_team_alert(admin, candidate, job, assigns)

      assert email.to == [{"", admin.email}]
      assert email.subject == "New Application: Test Candidate for Software Engineer"
      assert email.html_body =~ "New Application Received"
      assert email.html_body =~ candidate.name
      assert email.html_body =~ candidate.email
      assert email.html_body =~ job.title
      assert email.text_body =~ "New Application Received"
    end
  end
end
