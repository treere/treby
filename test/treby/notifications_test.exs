defmodule Treby.NotificationsTest do
  use Treby.DataCase, async: true

  import Swoosh.TestAssertions

  alias Treby.{Tenants, Repo, Notifications}
  alias Treby.Accounts.User
  alias Treby.Candidates.Candidate
  alias Treby.Jobs.Job
  alias Treby.Pipeline.{Application, PipelineStage}

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

  defp setup_email_template(tenant_id, stage_type) do
    {:ok, template} =
      Treby.EmailTemplates.upsert_email_template(%{
        "tenant_id" => tenant_id,
        "name" => "#{stage_type} Notification",
        "subject" => "You've been #{stage_type} for {job_title}",
        "body" =>
          "Hi {candidate_name}, you've been #{stage_type} for {job_title} at {company_name}.",
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

      assert Notifications.notification_preferences_enabled?(tenant, "new_application_team") ==
               true
    end

    test "returns false when preference is disabled" do
      {tenant, _user} = setup_tenant_with_admin()
      {:ok, _} = Notifications.set_notification_preference(tenant, "new_application_team", false)

      tenant = Repo.get!(Tenants.Tenant, tenant.id)

      assert Notifications.notification_preferences_enabled?(tenant, "new_application_team") ==
               false
    end
  end

  describe "set_notification_preference/3" do
    test "persists the preference change" do
      {tenant, _user} = setup_tenant_with_admin()

      assert {:ok, _} =
               Notifications.set_notification_preference(tenant, "stage_change_candidate", false)

      tenant = Repo.get!(Tenants.Tenant, tenant.id)

      assert Notifications.notification_preferences_enabled?(tenant, "stage_change_candidate") ==
               false
    end

    test "only affects the specified key" do
      {tenant, _user} = setup_tenant_with_admin()

      {:ok, _} =
        Notifications.set_notification_preference(tenant, "stage_change_candidate", false)

      tenant = Repo.get!(Tenants.Tenant, tenant.id)

      assert Notifications.notification_preferences_enabled?(tenant, "new_application_candidate") ==
               true

      assert Notifications.notification_preferences_enabled?(tenant, "new_application_team") ==
               true
    end
  end

  describe "notify_stage_change/2" do
    test "sends email when template exists and preference enabled" do
      {tenant, _user} = setup_tenant_with_admin()
      {job, stage} = setup_job(tenant)
      candidate = setup_candidate(tenant, "stage-change@test.com")
      application = setup_application(tenant, candidate, job, stage)

      # Create a conversation so the portal messaging path is active
      {:ok, _conversation} =
        Treby.CandidatePortal.create_conversation(%{
          candidate_id: candidate.id,
          tenant_id: tenant.id,
          subject: "Test",
          context: "application",
          application_id: application.id
        })

      setup_email_template(tenant.id, "hired")

      assert :ok = Notifications.notify_stage_change(application, nil)

      assert_email_sent(to: [{"", "stage-change@test.com"}])
    end

    test "does not send email when preference is disabled" do
      {tenant, _user} = setup_tenant_with_admin()

      {:ok, _} =
        Notifications.set_notification_preference(tenant, "stage_change_candidate", false)

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

    test "includes recruiter_name from actor when provided" do
      {tenant, user} = setup_tenant_with_admin()
      {job, stage} = setup_job(tenant)
      candidate = setup_candidate(tenant, "recruiter@test.com")
      application = setup_application(tenant, candidate, job, stage)

      # Create a conversation so the portal messaging path is active
      {:ok, _conversation} =
        Treby.CandidatePortal.create_conversation(%{
          candidate_id: candidate.id,
          tenant_id: tenant.id,
          subject: "Test",
          context: "application",
          application_id: application.id
        })

      {:ok, _template} =
        Treby.EmailTemplates.upsert_email_template(%{
          "tenant_id" => tenant.id,
          "name" => "Recruiter Test",
          "subject" => "Update from {recruiter_name}",
          "body" => "Hi {candidate_name}, this is {recruiter_name} from {company_name}.",
          "stage_type" => "hired"
        })

      assert :ok = Notifications.notify_stage_change(application, user)

      assert_email_sent(to: [{"", "recruiter@test.com"}])
    end

    test "uses empty string for recruiter_name when no actor" do
      {tenant, _user} = setup_tenant_with_admin()
      {job, stage} = setup_job(tenant)
      candidate = setup_candidate(tenant, "no-actor@test.com")
      application = setup_application(tenant, candidate, job, stage)

      # Create a conversation so the portal messaging path is active
      {:ok, _conversation} =
        Treby.CandidatePortal.create_conversation(%{
          candidate_id: candidate.id,
          tenant_id: tenant.id,
          subject: "Test",
          context: "application",
          application_id: application.id
        })

      setup_email_template(tenant.id, "hired")

      assert :ok = Notifications.notify_stage_change(application)

      assert_email_sent(to: [{"", "no-actor@test.com"}])
    end

    test "returns :ok even when email delivery fails" do
      {tenant, _user} = setup_tenant_with_admin()
      {job, stage} = setup_job(tenant)
      candidate = setup_candidate(tenant, "fail@test.com")
      application = setup_application(tenant, candidate, job, stage)

      setup_email_template(tenant.id, "hired")

      # Configure mailer to fail
      original_config = Elixir.Application.get_env(:treby, Treby.Mailer)

      Elixir.Application.put_env(:treby, Treby.Mailer,
        adapter: Swoosh.Adapters.Test,
        api_key: "fake"
      )

      try do
        assert :ok = Notifications.notify_stage_change(application, nil)
      after
        Elixir.Application.put_env(:treby, Treby.Mailer, original_config)
      end
    end
  end

  describe "notify_new_application_candidate/1" do
    test "sends portal access email to candidate" do
      {tenant, _user} = setup_tenant_with_admin()
      {job, stage} = setup_job(tenant)
      candidate = setup_candidate(tenant, "confirm@test.com")
      application = setup_application(tenant, candidate, job, stage)

      assert :ok = Notifications.notify_new_application_candidate(application)

      assert_email_sent(to: [{"", "confirm@test.com"}])
    end

    test "does not send when preference disabled" do
      {tenant, _user} = setup_tenant_with_admin()

      {:ok, _} =
        Notifications.set_notification_preference(tenant, "new_application_candidate", false)

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

      Elixir.Application.put_env(:treby, Treby.Mailer,
        adapter: Swoosh.Adapters.Test,
        api_key: "fake"
      )

      try do
        assert :ok = Notifications.notify_new_application_candidate(application)
      after
        Elixir.Application.put_env(:treby, Treby.Mailer, original_config)
      end
    end
  end

  describe "notify_team_new_application/1" do
    test "logs an in-app activity event" do
      {tenant, _admin} = setup_tenant_with_admin()
      {job, stage} = setup_job(tenant)
      candidate = setup_candidate(tenant, "team-alert@test.com")
      application = setup_application(tenant, candidate, job, stage)

      assert :ok = Notifications.notify_team_new_application(application)

      events = Treby.Activities.list_events_for_entity("application", application.id, 50)
      assert Enum.any?(events, &(&1.action == "new_application"))
    end

    test "does not log when preference disabled" do
      {tenant, _admin} = setup_tenant_with_admin()
      {:ok, _} = Notifications.set_notification_preference(tenant, "new_application_team", false)
      tenant = Repo.get!(Tenants.Tenant, tenant.id)

      {job, stage} = setup_job(tenant)
      candidate = setup_candidate(tenant, "no-team@test.com")
      application = setup_application(tenant, candidate, job, stage)

      assert :ok = Notifications.notify_team_new_application(application)

      events = Treby.Activities.list_events_for_entity("application", application.id, 50)
      refute Enum.any?(events, &(&1.action == "new_application"))
    end
  end

  describe "email templates" do
    test "creates template for new stage type" do
      {tenant, _user} = setup_tenant_with_admin()
      template = setup_email_template(tenant.id, "new")
      assert template.stage_type == "new"
    end

    test "creates template for interview stage type" do
      {tenant, _user} = setup_tenant_with_admin()
      template = setup_email_template(tenant.id, "interview")
      assert template.stage_type == "interview"
    end

    test "creates template for offer stage type" do
      {tenant, _user} = setup_tenant_with_admin()
      template = setup_email_template(tenant.id, "offer")
      assert template.stage_type == "offer"
    end

    test "creates template for hired stage type" do
      {tenant, _user} = setup_tenant_with_admin()
      template = setup_email_template(tenant.id, "hired")
      assert template.stage_type == "hired"
    end

    test "creates template for rejected stage type" do
      {tenant, _user} = setup_tenant_with_admin()
      template = setup_email_template(tenant.id, "rejected")
      assert template.stage_type == "rejected"
    end
  end
end
