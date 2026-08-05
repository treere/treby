defmodule TrebyWeb.CandidatesLive.IndexTest do
  use TrebyWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import Swoosh.TestAssertions

  alias Treby.{Tenants, Repo}
  alias Treby.Accounts.User

  defp setup_tenant do
    {:ok, tenant} =
      Tenants.create_tenant(%{
        name: "Candidates Test Corp",
        slug: "candidates-test-#{System.unique_integer([:positive])}"
      })

    {:ok, user} =
      tenant
      |> Ecto.build_assoc(:users)
      |> User.changeset(%{
        email: "cand-#{System.unique_integer([:positive])}@test.com",
        password: "password123",
        name: "Cand User",
        role: "admin"
      })
      |> Repo.insert()

    {tenant, user}
  end

  defp login_user(conn, user) do
    conn
    |> init_test_session(%{
      "user_id" => user.id,
      "tenant_id" => user.tenant_id
    })
  end

  describe "empty state" do
    test "shows empty state with CTAs when no candidates exist", %{conn: conn} do
      {_tenant, user} = setup_tenant()
      conn = login_user(conn, user)

      {:ok, view, _html} = live(conn, ~p"/app/candidates")

      html = render(view)
      assert html =~ "No candidates yet"
      assert html =~ "Add a candidate"
      assert html =~ "Import from CSV"
    end

    test "hides empty state when candidates exist", %{conn: conn} do
      {tenant, user} = setup_tenant()

      {:ok, _candidate} =
        tenant
        |> Ecto.build_assoc(:candidates)
        |> Treby.Candidates.Candidate.changeset(%{
          name: "Jane Smith",
          email: "jane@example.com"
        })
        |> Repo.insert()

      conn = login_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/app/candidates")

      html = render(view)
      refute html =~ "No candidates yet"
      assert html =~ "Jane Smith"
    end
  end

  describe "form validation" do
    test "shows flash error when creating candidate with empty name", %{conn: conn} do
      {_tenant, user} = setup_tenant()
      conn = login_user(conn, user)

      {:ok, view, _html} = live(conn, ~p"/app/candidates")

      view
      |> element("button", "+ Add Candidate")
      |> render_click()

      html =
        view
        |> form("#candidate-form", %{
          "candidate" => %{
            "name" => "",
            "email" => "test@example.com"
          }
        })
        |> render_submit()

      assert html =~ "Please review the errors below"
    end
  end

  describe "show page - edit validation" do
    test "shows flash error when saving edit with empty name", %{conn: conn} do
      {tenant, user} = setup_tenant()

      {:ok, candidate} =
        tenant
        |> Ecto.build_assoc(:candidates)
        |> Treby.Candidates.Candidate.changeset(%{
          name: "Valid Name",
          email: "valid@example.com"
        })
        |> Repo.insert()

      conn = login_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/app/candidates/#{candidate.id}")

      view |> element("button", "Edit") |> render_click()

      html =
        view
        |> form("#edit-candidate-form", %{
          "candidate" => %{
            "name" => "",
            "email" => "valid@example.com"
          }
        })
        |> render_submit()

      assert html =~ "Please review the errors below"
    end
  end

  describe "show page - compose email" do
    test "shows compose email button", %{conn: conn} do
      {tenant, user} = setup_tenant()

      {:ok, candidate} =
        tenant
        |> Ecto.build_assoc(:candidates)
        |> Treby.Candidates.Candidate.changeset(%{
          name: "Email Test",
          email: "emailtest@example.com"
        })
        |> Repo.insert()

      conn = login_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/app/candidates/#{candidate.id}")

      assert has_element?(view, "button", "Compose Email")
    end

    test "shows compose form when clicking compose", %{conn: conn} do
      {tenant, user} = setup_tenant()

      {:ok, candidate} =
        tenant
        |> Ecto.build_assoc(:candidates)
        |> Treby.Candidates.Candidate.changeset(%{
          name: "Compose Test",
          email: "compose@example.com"
        })
        |> Repo.insert()

      conn = login_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/app/candidates/#{candidate.id}")

      view
      |> element("button", "+ Compose Email")
      |> render_click()

      assert has_element?(view, "input[name=\"compose[subject]\"]")
      assert has_element?(view, "button", "Send Email")
    end

    test "hides compose form on cancel", %{conn: conn} do
      {tenant, user} = setup_tenant()

      {:ok, candidate} =
        tenant
        |> Ecto.build_assoc(:candidates)
        |> Treby.Candidates.Candidate.changeset(%{
          name: "Cancel Test",
          email: "cancel@example.com"
        })
        |> Repo.insert()

      conn = login_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/app/candidates/#{candidate.id}")

      view
      |> element("button", "+ Compose Email")
      |> render_click()

      assert has_element?(view, "button", "Send Email")

      view
      |> element("#compose-form button", "Cancel")
      |> render_click()

      refute has_element?(view, "button", "Send Email")
    end

    test "shows error when sending with empty subject", %{conn: conn} do
      {tenant, user} = setup_tenant()

      {:ok, candidate} =
        tenant
        |> Ecto.build_assoc(:candidates)
        |> Treby.Candidates.Candidate.changeset(%{
          name: "Subject Test",
          email: "subject@example.com"
        })
        |> Repo.insert()

      conn = login_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/app/candidates/#{candidate.id}")

      view
      |> element("button", "+ Compose Email")
      |> render_click()

      view
      |> form("#compose-form", %{
        "compose" => %{
          "subject" => "",
          "body" => "Hello"
        }
      })
      |> render_submit()

      assert render(view) =~ "Subject is required"
    end

    test "shows error when sending with empty body", %{conn: conn} do
      {tenant, user} = setup_tenant()

      {:ok, candidate} =
        tenant
        |> Ecto.build_assoc(:candidates)
        |> Treby.Candidates.Candidate.changeset(%{
          name: "Body Test",
          email: "body@example.com"
        })
        |> Repo.insert()

      conn = login_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/app/candidates/#{candidate.id}")

      view
      |> element("button", "+ Compose Email")
      |> render_click()

      view
      |> form("#compose-form", %{
        "compose" => %{
          "subject" => "Hello",
          "body" => ""
        }
      })
      |> render_submit()

      assert render(view) =~ "Message body is required"
    end

    test "sends email successfully", %{conn: conn} do
      {tenant, user} = setup_tenant()

      {:ok, candidate} =
        tenant
        |> Ecto.build_assoc(:candidates)
        |> Treby.Candidates.Candidate.changeset(%{
          name: "Send Test",
          email: "send@example.com"
        })
        |> Repo.insert()

      conn = login_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/app/candidates/#{candidate.id}")

      view
      |> element("button", "+ Compose Email")
      |> render_click()

      view
      |> form("#compose-form", %{
        "compose" => %{
          "subject" => "Hello from Treby",
          "body" => "This is a test email"
        }
      })
      |> render_submit()

      assert render(view) =~ "Email sent"
      assert_email_sent(subject: "Hello from Treby", to: [{"", "send@example.com"}])
    end

    test "schedules email when schedule mode is selected", %{conn: conn} do
      {tenant, user} = setup_tenant()

      {:ok, candidate} =
        tenant
        |> Ecto.build_assoc(:candidates)
        |> Treby.Candidates.Candidate.changeset(%{
          name: "Schedule Test",
          email: "schedule@example.com"
        })
        |> Repo.insert()

      conn = login_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/app/candidates/#{candidate.id}")

      view
      |> element("button", "+ Compose Email")
      |> render_click()

      assert render(view) =~ "Schedule for later"

      scheduled_at =
        Date.add(Date.utc_today(), 1)
        |> DateTime.new!(~T[09:00:00], "Etc/UTC")

      view
      |> render_submit("send_compose", %{
        "compose" => %{
          "subject" => "Scheduled hello",
          "body" => "Sent later",
          "mode" => "schedule",
          "scheduled_at" => DateTime.to_iso8601(scheduled_at),
          "jitter_minutes" => 0
        }
      })

      assert render(view) =~ "Email scheduled"

      queued = Repo.get_by!(Treby.EmailQueue.ScheduledEmail, to_address: "schedule@example.com")
      assert queued.email_type == "compose"
      assert queued.subject == "Scheduled hello"
    end
  end

  describe "bulk email - scheduling" do
    defp create_job_pipeline(tenant) do
      {:ok, job} =
        Treby.Jobs.create_job(%{
          tenant_id: tenant.id,
          title: "Engineer",
          description: "Backend engineer"
        })

      {:ok, pipeline} =
        Treby.Pipeline.create_pipeline(%{
          name: "Default",
          tenant_id: tenant.id,
          is_default: true
        })

      {:ok, stage} =
        Treby.Pipeline.create_pipeline_stage(%{
          name: "Applied",
          position: 1,
          pipeline_id: pipeline.id,
          tenant_id: tenant.id,
          stage_type: "applied"
        })

      {job, stage}
    end

    defp create_candidate_with_application(tenant, job, stage, name, email) do
      {:ok, candidate} =
        tenant
        |> Ecto.build_assoc(:candidates)
        |> Treby.Candidates.Candidate.changeset(%{name: name, email: email})
        |> Repo.insert()

      {:ok, _application} =
        Treby.Pipeline.create_application(%{
          tenant_id: tenant.id,
          job_id: job.id,
          candidate_id: candidate.id,
          pipeline_stage_id: stage.id,
          applied_at: DateTime.utc_now()
        })

      candidate
    end

    test "shows schedule options in bulk composer", %{conn: conn} do
      {tenant, user} = setup_tenant()
      {job, stage} = create_job_pipeline(tenant)

      candidate =
        create_candidate_with_application(tenant, job, stage, "Bulk Test", "bulk@example.com")

      conn = login_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/app/candidates")

      view |> element(~s{input[phx-value-id="#{candidate.id}"]}) |> render_click()

      view
      |> element("select[name=bulk_action]")
      |> render_change(%{"bulk_action" => "send_email"})

      assert render(view) =~ "Schedule for later"

      view |> element(~s{input[phx-value-mode="schedule"]}) |> render_click()

      assert has_element?(view, "button", "Tomorrow 9:00")
      assert has_element?(view, "button", "Tomorrow 14:00")
      assert has_element?(view, "button", "Next Monday")
    end

    test "schedules bulk emails when schedule mode selected", %{conn: conn} do
      {tenant, user} = setup_tenant()
      {job, stage} = create_job_pipeline(tenant)

      candidate =
        create_candidate_with_application(tenant, job, stage, "Bulk Test", "bulk@example.com")

      conn = login_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/app/candidates")

      view |> element(~s{input[phx-value-id="#{candidate.id}"]}) |> render_click()

      view
      |> element("select[name=bulk_action]")
      |> render_change(%{"bulk_action" => "send_email"})

      view |> element(~s{input[phx-value-mode="schedule"]}) |> render_click()
      view |> element(~s{button[phx-value-label="tomorrow_9"]}) |> render_click()

      view
      |> element(~s{input[name="bulk_email_subject"]})
      |> render_change(%{"bulk_email_subject" => "Bulk scheduled"})

      view
      |> element(~s{textarea[name="bulk_email_body"]})
      |> render_change(%{"bulk_email_body" => "Hello {candidate_name}"})

      view |> element("button", "Send") |> render_click()

      assert render(view) =~ "1 emails scheduled"

      queued = Repo.get_by!(Treby.EmailQueue.ScheduledEmail, to_address: "bulk@example.com")
      assert queued.email_type == "bulk"
      assert queued.subject == "Bulk scheduled"
    end
  end

  describe "bulk compare" do
    test "shows Compare button after selecting the action", %{conn: conn} do
      {tenant, user} = setup_tenant()
      {job, stage} = create_job_pipeline(tenant)

      alice =
        create_candidate_with_application(
          tenant,
          job,
          stage,
          "Alice Compare",
          "alicec@example.com"
        )

      bob =
        create_candidate_with_application(tenant, job, stage, "Bob Compare", "bobc@example.com")

      conn = login_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/app/candidates")

      view |> element(~s{input[phx-value-id="#{alice.id}"]}) |> render_click()
      view |> element(~s{input[phx-value-id="#{bob.id}"]}) |> render_click()

      view
      |> element("select[name=bulk_action]")
      |> render_change(%{"bulk_action" => "compare"})

      assert has_element?(view, "button", "Compare")
    end

    test "navigates to compare page with selected candidate ids", %{conn: conn} do
      {tenant, user} = setup_tenant()
      {job, stage} = create_job_pipeline(tenant)

      alice =
        create_candidate_with_application(
          tenant,
          job,
          stage,
          "Alice Compare",
          "alicec2@example.com"
        )

      bob =
        create_candidate_with_application(tenant, job, stage, "Bob Compare", "bobc2@example.com")

      conn = login_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/app/candidates")

      view |> element(~s{input[phx-value-id="#{alice.id}"]}) |> render_click()
      view |> element(~s{input[phx-value-id="#{bob.id}"]}) |> render_click()

      view
      |> element("select[name=bulk_action]")
      |> render_change(%{"bulk_action" => "compare"})

      view |> element("button", "Compare") |> render_click()

      expected = ~p"/app/candidates/compare?ids=#{Enum.join([bob.id, alice.id], ",")}"
      assert_redirect(view, expected)
    end
  end
end
