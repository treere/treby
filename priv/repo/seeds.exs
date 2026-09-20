# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# The seed data is intentionally rich: it produces a realistic hiring
# workspace so screenshots, analytics, and the docs showcase pages all show
# meaningful state instead of empty lists.
#
# Login with: admin@acme.com / password123

defmodule Treby.Seeds do
  @moduledoc false

  import Ecto.Query

  alias Treby.Repo

  @password "password123"

  def run do
    tenant = create_tenant()
    pipeline = Treby.Pipeline.create_default_pipeline_stages(tenant)
    stages = stage_map(pipeline.id)
    users = create_users(tenant)
    assign_stage_roles(stages, users)

    jobs = create_jobs(tenant, pipeline.id)
    candidates = create_candidates(tenant)

    applications = create_applications(tenant, jobs, candidates, stages)
    create_notes(users, applications)
    create_interviews(tenant, users, applications)
    create_conversations(tenant, users, candidates, applications)
    create_scheduled_messages(tenant, users, candidates, applications)

    create_career_page(tenant)
    create_custom_fields(tenant, users)
    create_scorecard_template(tenant, users)
    create_email_templates(tenant, users)
    create_availability(tenant, users)
    create_calendar_connection(tenant, users)
    create_webhooks(tenant, users)
    create_notifications(tenant, users)
    create_data_privacy_requests(tenant, users)
    create_ai_conversation(tenant, users)
    create_job_views(tenant, jobs)
    create_audit_events(tenant, users, jobs, candidates, applications)
    create_tenant_activities(tenant, users, candidates, applications)
    create_beta_workspace()

    IO.puts("\nSeed data created successfully!")
    IO.puts("Login with: admin@acme.com / #{@password}")
    IO.puts("Career page: /acme/careers")
    IO.puts("Portal login: /acme/portal/login (use alice@example.com)")
  end

  # ------------------------------------------------------------------
  # Helpers
  # ------------------------------------------------------------------

  defp now, do: DateTime.utc_now() |> DateTime.truncate(:second)

  defp days_ago(n), do: DateTime.add(now(), -n, :day)
  defp days_ahead(n), do: DateTime.add(now(), n, :day)

  # Applications use :utc_datetime_usec, so their timestamps must keep
  # microsecond precision (unlike every other schema here).
  defp days_ago_usec(n), do: DateTime.add(DateTime.utc_now(), -n, :day)

  defp stage_map(pipeline_id) do
    Treby.Pipeline.list_pipeline_stages(pipeline_id)
    |> Map.new(&{&1.name, &1})
  end

  # ------------------------------------------------------------------
  # Tenant, users, memberships
  # ------------------------------------------------------------------

  defp create_tenant do
    tenant =
      %Treby.Tenants.Tenant{}
      |> Treby.Tenants.Tenant.changeset(%{
        name: "Acme Corp",
        slug: "acme",
        timezone: "Europe/Rome"
      })
      |> Repo.insert!()

    IO.puts("Created tenant: #{tenant.name}")
    tenant
  end

  defp create_users(tenant) do
    users = %{
      admin: create_user(tenant, "admin@acme.com", "Admin User", "admin"),
      member: create_user(tenant, "member@acme.com", "Team Member", "member"),
      recruiter: create_user(tenant, "sofia@acme.com", "Sofia Conti", "member"),
      hiring: create_user(tenant, "luca@acme.com", "Luca Ferrari", "member")
    }

    IO.puts("Created #{map_size(users)} users")
    users
  end

  defp create_user(tenant, email, name, role) do
    user =
      Ecto.build_assoc(tenant, :users)
      |> Treby.Accounts.User.changeset(%{
        email: email,
        password: @password,
        name: name,
        role: role
      })
      |> Repo.insert!()

    {:ok, _} =
      Treby.Memberships.create_membership(%{
        user_id: user.id,
        tenant_id: tenant.id,
        role: role
      })

    IO.puts("  user: #{user.email}")
    user
  end

  # ------------------------------------------------------------------
  # Stage roles (examiners / reviewers / advancers)
  # ------------------------------------------------------------------

  defp assign_stage_roles(stages, users) do
    # Admin is intentionally left off the Interview examiners: the seeded
    # (demo) Google connection would make external free/busy lookups fail, and
    # the candidate portal schedule page picks the first eligible examiner.
    examiners = [users.member, users.recruiter]
    reviewers = [users.admin, users.member]
    advancers = [users.admin]

    Enum.each(examiners, &Treby.Pipeline.assign_examiner(stages["Interview"], &1.id))

    Enum.each(reviewers, fn user ->
      Treby.Pipeline.assign_reviewer(stages["Screen"], user.id)
      Treby.Pipeline.assign_reviewer(stages["Phone Screen"], user.id)
    end)

    Enum.each(advancers, fn user ->
      for name <- ["Screen", "Phone Screen", "Interview", "Offer", "Hired", "Rejected"] do
        Treby.Pipeline.assign_advancer(stages[name], user.id)
      end
    end)

    IO.puts("  assigned stage examiners/reviewers/advancers")
  end

  # ------------------------------------------------------------------
  # Jobs
  # ------------------------------------------------------------------

  defp create_jobs(tenant, pipeline_id) do
    # Inserted oldest first: the hero job is last so it is first in
    # `Jobs.list_jobs/1` (ordered by inserted_at desc) and becomes the
    # default target for job-scoped screenshots.
    specs = [
      %{
        title: "Customer Success Manager",
        description:
          "Own the relationship with our largest customers. You will onboard new accounts, drive adoption, and turn feedback into product improvements.",
        salary_range: "$70k-$95k",
        location: "Remote (EU)",
        employment_type: "full_time",
        workplace_type: "remote",
        status: "open",
        inserted_at: days_ago(48)
      },
      %{
        title: "Data Analyst",
        description:
          "Turn hiring data into decisions. Build dashboards, own reporting, and help the team understand the funnel end to end.",
        salary_range: "$80k-$105k",
        location: "Milan, Italy",
        employment_type: "full_time",
        workplace_type: "hybrid",
        status: "closed",
        visible: false,
        inserted_at: days_ago(40)
      },
      %{
        title: "DevOps Engineer",
        description:
          "Help us build and maintain our infrastructure. Experience with AWS, Docker, and Kubernetes preferred.",
        salary_range: "$110k-$150k",
        location: "Berlin, Germany",
        employment_type: "full_time",
        workplace_type: "hybrid",
        status: "open",
        inserted_at: days_ago(32)
      },
      %{
        title: "Product Designer",
        description:
          "Join our design team to create beautiful, intuitive user experiences. Experience with Figma and design systems required.",
        salary_range: "$100k-$140k",
        location: "Remote (EU)",
        employment_type: "full_time",
        workplace_type: "remote",
        status: "open",
        inserted_at: days_ago(24)
      },
      %{
        title: "Senior Elixir Developer",
        description:
          "We're looking for an experienced Elixir developer to join our team. You'll work on building scalable, fault-tolerant systems with Phoenix LiveView.",
        salary_range: "$120k-$160k",
        location: "Remote (EU)",
        employment_type: "full_time",
        workplace_type: "remote",
        status: "open",
        inserted_at: days_ago(6)
      }
    ]

    jobs =
      Enum.map(specs, fn spec ->
        job =
          Ecto.build_assoc(tenant, :jobs)
          |> Treby.Jobs.Job.changeset(Map.drop(spec, [:inserted_at]))
          |> Ecto.Changeset.change(%{
            pipeline_id: pipeline_id,
            inserted_at: spec.inserted_at,
            updated_at: spec.inserted_at
          })
          |> Repo.insert!()

        IO.puts("  job: #{job.title}")
        job
      end)

    Map.new(jobs, &{&1.title, &1})
  end

  # ------------------------------------------------------------------
  # Candidates
  # ------------------------------------------------------------------

  defp create_candidates(tenant) do
    specs = [
      %{
        name: "Alice Johnson",
        email: "alice@example.com",
        phone: "555-0101",
        linkedin_url: "https://linkedin.com/in/alicejohnson",
        custom_fields: %{"Portfolio URL" => "https://alice.dev", "Years of experience" => 7}
      },
      %{
        name: "Bob Smith",
        email: "bob@example.com",
        phone: "555-0102",
        linkedin_url: "https://linkedin.com/in/bobsmith"
      },
      %{name: "Carol Williams", email: "carol@example.com", phone: "555-0103"},
      %{name: "David Brown", email: "david@example.com", phone: "555-0104"},
      %{name: "Eve Davis", email: "eve@example.com", phone: "555-0105"},
      %{name: "Frank Miller", email: "frank@example.com", phone: "555-0120"},
      %{name: "Frank Miller", email: "frank.m@example.com", phone: "555-0120"},
      %{name: "Grace Hopper", email: "grace.hopper@company.com", phone: "555-0122"},
      %{name: "Grace Hopper", email: "grace.hopper@gmail.com", phone: "+39 555-0122"},
      %{name: "Heidi Lee", email: "heidi.lee@acme.com", phone: "555-0123"},
      %{name: "Heidi Lee", email: "heidi.lee@outlook.com", phone: "555-0124"},
      %{name: "Ivan Petrov", email: "ivan@example.com", phone: "555-0130"},
      %{
        name: "Julia Rossi",
        email: "julia@example.com",
        phone: "555-0131",
        linkedin_url: "https://linkedin.com/in/juliarossi"
      },
      %{name: "Marco Bianchi", email: "marco@example.com", phone: "555-0132"},
      %{name: "Nina Kowalski", email: "nina@example.com", phone: "555-0133"},
      %{name: "Omar Haddad", email: "omar@example.com", phone: "555-0134"}
    ]

    candidates =
      Enum.map(specs, fn spec ->
        candidate =
          Ecto.build_assoc(tenant, :candidates)
          |> Treby.Candidates.Candidate.changeset(spec)
          |> Repo.insert!()

        candidate
      end)

    IO.puts("  created #{length(candidates)} candidates (incl. duplicate groups)")
    Map.new(candidates, &{&1.email, &1})
  end

  # ------------------------------------------------------------------
  # Applications + stage history
  # ------------------------------------------------------------------

  defp create_applications(tenant, jobs, candidates, stages) do
    specs = [
      # --- Senior Elixir Developer (hero job) ---
      %{
        c: "alice@example.com",
        j: "Senior Elixir Developer",
        stage: "Offer",
        applied: 42,
        updated: 10,
        history: [
          {"New", 42},
          {"Screen", 36},
          {"Phone Screen", 31},
          {"Interview", 24},
          {"Offer", 10}
        ]
      },
      %{
        c: "bob@example.com",
        j: "Senior Elixir Developer",
        stage: "Interview",
        applied: 20,
        updated: 3,
        history: [{"New", 20}, {"Screen", 14}, {"Interview", 3}]
      },
      %{
        c: "carol@example.com",
        j: "Senior Elixir Developer",
        stage: "Interview",
        applied: 30,
        updated: 6,
        history: [{"New", 30}, {"Screen", 24}, {"Phone Screen", 18}, {"Interview", 6}]
      },
      %{
        c: "david@example.com",
        j: "Senior Elixir Developer",
        stage: "Screen",
        applied: 8,
        updated: 5,
        history: [{"New", 8}, {"Screen", 5}]
      },
      %{
        c: "eve@example.com",
        j: "Senior Elixir Developer",
        stage: "New",
        applied: 2,
        updated: 2,
        history: []
      },
      %{
        c: "ivan@example.com",
        j: "Senior Elixir Developer",
        stage: "Rejected",
        applied: 26,
        updated: 9,
        history: [{"New", 26}, {"Screen", 20}, {"Rejected", 9}],
        rejection_reason: "Not enough production Elixir experience"
      },
      %{
        c: "julia@example.com",
        j: "Senior Elixir Developer",
        stage: "Hired",
        applied: 55,
        updated: 3,
        history: [
          {"New", 55},
          {"Screen", 48},
          {"Phone Screen", 42},
          {"Interview", 33},
          {"Offer", 20},
          {"Hired", 3}
        ]
      },
      %{
        c: "marco@example.com",
        j: "Senior Elixir Developer",
        stage: "Interview",
        applied: 12,
        updated: 4,
        history: [{"New", 12}, {"Screen", 9}, {"Interview", 4}]
      },

      # --- Product Designer ---
      %{
        c: "grace.hopper@company.com",
        j: "Product Designer",
        stage: "Interview",
        applied: 22,
        updated: 2,
        history: [{"New", 22}, {"Screen", 15}, {"Interview", 2}]
      },
      %{
        c: "heidi.lee@acme.com",
        j: "Product Designer",
        stage: "Screen",
        applied: 6,
        updated: 3,
        history: [{"New", 6}, {"Screen", 3}]
      },
      %{
        c: "frank@example.com",
        j: "Product Designer",
        stage: "New",
        applied: 1,
        updated: 1,
        history: []
      },
      %{
        c: "nina@example.com",
        j: "Product Designer",
        stage: "Offer",
        applied: 28,
        updated: 5,
        history: [{"New", 28}, {"Screen", 22}, {"Interview", 14}, {"Offer", 5}]
      },
      %{
        c: "omar@example.com",
        j: "Product Designer",
        stage: "Rejected",
        applied: 18,
        updated: 7,
        history: [{"New", 18}, {"Rejected", 7}],
        rejection_reason: "Portfolio did not match the role"
      },

      # --- DevOps Engineer ---
      %{
        c: "alice@example.com",
        j: "DevOps Engineer",
        stage: "Interview",
        applied: 15,
        updated: 4,
        history: [{"New", 15}, {"Screen", 10}, {"Interview", 4}]
      },
      %{
        c: "carol@example.com",
        j: "DevOps Engineer",
        stage: "New",
        applied: 4,
        updated: 4,
        history: []
      },
      %{
        c: "frank@example.com",
        j: "DevOps Engineer",
        stage: "Interview",
        applied: 25,
        updated: 11,
        history: [{"New", 25}, {"Screen", 19}, {"Interview", 11}]
      },
      %{
        c: "david@example.com",
        j: "DevOps Engineer",
        stage: "New",
        applied: 3,
        updated: 3,
        history: []
      },

      # --- Customer Success Manager ---
      %{
        c: "eve@example.com",
        j: "Customer Success Manager",
        stage: "Screen",
        applied: 9,
        updated: 6,
        history: [{"New", 9}, {"Screen", 6}]
      },
      %{
        c: "grace.hopper@company.com",
        j: "Customer Success Manager",
        stage: "New",
        applied: 5,
        updated: 5,
        history: []
      },
      %{
        c: "heidi.lee@acme.com",
        j: "Customer Success Manager",
        stage: "New",
        applied: 2,
        updated: 2,
        history: []
      },

      # --- Data Analyst (closed) ---
      %{
        c: "nina@example.com",
        j: "Data Analyst",
        stage: "Rejected",
        applied: 40,
        updated: 30,
        history: [{"New", 40}, {"Rejected", 30}],
        rejection_reason: "Position closed"
      },
      %{
        c: "omar@example.com",
        j: "Data Analyst",
        stage: "New",
        applied: 35,
        updated: 35,
        history: []
      }
    ]

    applications =
      Enum.map(specs, fn spec ->
        candidate = candidates[spec.c]
        job = jobs[spec.j]
        stage = stages[spec.stage]

        app =
          Ecto.build_assoc(tenant, :applications)
          |> Ecto.Changeset.change(%{
            job_id: job.id,
            candidate_id: candidate.id,
            pipeline_stage_id: stage.id,
            applied_at: days_ago(spec.applied),
            anagrafica: Treby.Pipeline.build_anagrafica(candidate),
            rejection_reason: spec[:rejection_reason],
            inserted_at: days_ago_usec(spec.applied),
            updated_at: days_ago_usec(spec.updated)
          })
          |> Repo.insert!()

        log_stage_history(tenant, app, spec.history)
        Map.put(spec, :app, app)
      end)

    IO.puts("  created #{length(applications)} applications across #{map_size(stages)} stages")

    # Keyed lookup used by later seed steps.
    Enum.reduce(applications, %{}, fn spec, acc ->
      Map.put(acc, {spec.c, spec.j}, spec.app)
    end)
  end

  defp log_stage_history(_tenant, _app, history) when length(history) < 2, do: :ok

  defp log_stage_history(tenant, app, history) do
    history
    |> Enum.drop(1)
    |> Enum.each(fn {stage_name, days} ->
      %Treby.Activities.ActivityLog{}
      |> Ecto.Changeset.change(%{
        action: "application_stage_changed",
        entity_type: "application",
        entity_id: app.id,
        tenant_id: tenant.id,
        metadata: %{"new_stage" => stage_name},
        inserted_at: days_ago(days),
        updated_at: days_ago(days)
      })
      |> Repo.insert!()
    end)
  end

  # ------------------------------------------------------------------
  # Notes
  # ------------------------------------------------------------------

  defp create_notes(users, applications) do
    notes = [
      {applications[{"alice@example.com", "Senior Elixir Developer"}], users.admin,
       "Strong system design answers. Would be a great fit for the platform team.", "feedback",
       5},
      {applications[{"alice@example.com", "Senior Elixir Developer"}], users.member,
       "Very clear communicator, asked good questions about our architecture.", "feedback", 4},
      {applications[{"alice@example.com", "Senior Elixir Developer"}], users.recruiter,
       "Available to start in 4 weeks.", "note", nil},
      {applications[{"carol@example.com", "Senior Elixir Developer"}], users.admin,
       "Solid coding exercise, a bit light on distributed systems.", "feedback", 3},
      {applications[{"bob@example.com", "Senior Elixir Developer"}], users.recruiter,
       "Referred by a current employee.", "note", nil},
      {applications[{"julia@example.com", "Senior Elixir Developer"}], users.admin,
       "Signed offer. Onboarding scheduled.", "note", nil}
    ]

    Enum.each(notes, fn {app, author, content, type, rating} ->
      %Treby.Notes.Note{}
      |> Ecto.Changeset.change(%{
        content: content,
        type: type,
        rating: rating,
        tenant_id: app.tenant_id,
        application_id: app.id,
        author_id: author.id
      })
      |> Repo.insert!()
    end)

    IO.puts("  created #{length(notes)} notes/feedback")
  end

  # ------------------------------------------------------------------
  # Interviews + scorecards
  # ------------------------------------------------------------------

  defp create_interviews(_tenant, users, applications) do
    scored = %{
      "hire" => %{
        "Technical skills" => 5,
        "Communication" => 5,
        "Problem solving" => 5,
        "Culture fit" => "yes"
      },
      "lean_hire" => %{
        "Technical skills" => 4,
        "Communication" => 4,
        "Problem solving" => 4,
        "Culture fit" => "yes"
      },
      "lean_no_hire" => %{
        "Technical skills" => 3,
        "Communication" => 3,
        "Problem solving" => 3,
        "Culture fit" => "maybe"
      }
    }

    specs = [
      %{
        app: {"alice@example.com", "Senior Elixir Developer"},
        start: -24,
        duration: 60,
        status: "completed",
        examiners: [:admin, :member],
        scorecards: %{admin: "hire", member: "lean_hire"}
      },
      %{
        app: {"julia@example.com", "Senior Elixir Developer"},
        start: -20,
        duration: 45,
        status: "completed",
        examiners: [:admin, :recruiter],
        scorecards: %{admin: "hire", recruiter: "hire"}
      },
      %{
        app: {"carol@example.com", "Senior Elixir Developer"},
        start: -6,
        duration: 60,
        status: "completed",
        examiners: [:admin, :member],
        scorecards: %{admin: "hire", member: "lean_hire"}
      },
      %{
        app: {"frank@example.com", "DevOps Engineer"},
        start: -11,
        duration: 60,
        status: "completed",
        examiners: [:admin, :member],
        scorecards: %{admin: "lean_no_hire"}
      },
      %{
        app: {"bob@example.com", "Senior Elixir Developer"},
        start: 2,
        duration: 45,
        status: "scheduled",
        examiners: [:admin, :member],
        scorecards: %{}
      },
      %{
        app: {"marco@example.com", "Senior Elixir Developer"},
        start: 4,
        duration: 45,
        status: "scheduled",
        examiners: [:admin, :recruiter],
        scorecards: %{}
      },
      %{
        app: {"grace.hopper@company.com", "Product Designer"},
        start: 5,
        duration: 30,
        status: "scheduled",
        examiners: [:member, :hiring],
        scorecards: %{}
      }
    ]

    Enum.each(specs, fn spec ->
      app = applications[spec.app]
      start = if spec.start < 0, do: days_ago(-spec.start), else: days_ahead(spec.start)
      start = start |> DateTime.add(9, :hour) |> DateTime.truncate(:second)
      finish = DateTime.add(start, spec.duration, :minute)

      event =
        %Treby.Interviews.InterviewEvent{}
        |> Treby.Interviews.InterviewEvent.changeset(%{
          start_at_utc: start,
          end_at_utc: finish,
          duration_minutes: spec.duration,
          status: spec.status,
          video_conf_url: "https://meet.jit.si/treby-#{String.slice(app.id, 0, 8)}",
          scheduled_by_id: users.admin.id,
          application_id: app.id,
          tenant_id: app.tenant_id
        })
        |> Ecto.Changeset.change(%{
          inserted_at: DateTime.add(start, -3, :day),
          updated_at: DateTime.add(start, -3, :day)
        })
        |> Repo.insert!()

      Enum.each(spec.examiners, fn key ->
        %Treby.Interviews.EventExaminer{}
        |> Ecto.Changeset.change(%{
          interview_event_id: event.id,
          user_id: users[key].id,
          status: if(spec.status == "cancelled", do: "cancelled", else: "scheduled"),
          inserted_at: event.inserted_at
        })
        |> Repo.insert!()
      end)

      Enum.each(spec.scorecards, fn {key, recommendation} ->
        %Treby.Scorecards.Scorecard{}
        |> Treby.Scorecards.Scorecard.changeset(%{
          scores: scored[recommendation],
          recommendation: recommendation,
          notes: "Detailed notes from the #{key} interview.",
          interview_event_id: event.id,
          interviewer_id: users[key].id,
          tenant_id: app.tenant_id
        })
        |> Ecto.Changeset.change(%{
          inserted_at: DateTime.add(start, 1, :day),
          updated_at: DateTime.add(start, 1, :day)
        })
        |> Repo.insert!()
      end)
    end)

    IO.puts("  created #{length(specs)} interviews with scorecards")
  end

  # ------------------------------------------------------------------
  # Candidate portal conversations + messages
  # ------------------------------------------------------------------

  defp create_conversations(tenant, users, candidates, applications) do
    alice = candidates["alice@example.com"]
    alice_app = applications[{"alice@example.com", "Senior Elixir Developer"}]

    {:ok, conv} =
      Treby.CandidatePortal.create_conversation(%{
        candidate_id: alice.id,
        tenant_id: tenant.id,
        application_id: alice_app.id,
        subject: "Your application at Acme Corp",
        context: "application",
        last_message_at: days_ago(10)
      })

    messages(conv, [
      {users.recruiter, "recruiter",
       "Hi Alice, thanks for applying! We reviewed your profile and would love to schedule a first call.",
       "text", 12},
      {nil, "candidate",
       "Hi Sofia, thank you! I'd be happy to chat. I'm generally available in the mornings.",
       "text", 11},
      {nil, "system", "Your application has moved to Interview.", "status_update", 10}
    ])

    {:ok, _general} =
      Treby.CandidatePortal.create_conversation(%{
        candidate_id: alice.id,
        tenant_id: tenant.id,
        subject: "Welcome to Acme Corp",
        context: "general",
        last_message_at: days_ago(20)
      })

    {:ok, bob_conv} =
      Treby.CandidatePortal.create_conversation(%{
        candidate_id: candidates["bob@example.com"].id,
        tenant_id: tenant.id,
        application_id: applications[{"bob@example.com", "Senior Elixir Developer"}].id,
        subject: "Interview invitation",
        context: "interview",
        last_message_at: days_ago(2)
      })

    messages(bob_conv, [
      {users.recruiter, "recruiter",
       "Hi Bob, we'd like to invite you to a technical interview. Does Thursday work for you?",
       "interview_invite", 3},
      {nil, "candidate", "Thursday works great, thank you!", "text", 2}
    ])

    IO.puts("  created portal conversations and messages")
  end

  defp messages(conv, list) do
    Enum.each(list, fn {user, sender_type, body, type, days} ->
      %Treby.CandidatePortal.Message{}
      |> Ecto.Changeset.change(%{
        conversation_id: conv.id,
        sender_type: sender_type,
        sender_id: user && user.id,
        body: body,
        message_type: type,
        inserted_at: days_ago(days),
        updated_at: days_ago(days)
      })
      |> Repo.insert!()
    end)
  end

  # ------------------------------------------------------------------
  # Scheduled messages (queue page)
  # ------------------------------------------------------------------

  defp create_scheduled_messages(tenant, users, candidates, _applications) do
    conv_for = fn email, context ->
      Repo.one(
        from c in Treby.CandidatePortal.Conversation,
          where: c.candidate_id == ^candidates[email].id and c.context == ^context,
          order_by: [asc: c.inserted_at],
          limit: 1
      )
    end

    specs = [
      %{
        email: "alice@example.com",
        context: "application",
        body:
          "Hi Alice, looking forward to our next conversation. Here is the agenda for the interview.",
        send_at: days_ahead(1),
        status: "scheduled"
      },
      %{
        email: "bob@example.com",
        context: "interview",
        body: "Hi Bob, a friendly reminder about your interview on Thursday.",
        send_at: days_ahead(2),
        status: "scheduled"
      },
      %{
        email: "carol@example.com",
        context: "application",
        body: "Hi Carol, thanks again for your time — we will be in touch shortly.",
        send_at: days_ahead(3),
        status: "scheduled"
      },
      %{
        email: "bob@example.com",
        context: "interview",
        body: "Hi Bob, confirming the interview details for Thursday.",
        send_at: days_ago(1),
        status: "sent"
      },
      %{
        email: "alice@example.com",
        context: "application",
        body: "Hi Alice, we received your updated portfolio, thank you!",
        send_at: days_ago(2),
        status: "sent"
      },
      %{
        email: "carol@example.com",
        context: "application",
        body: "Hi Carol, following up on the take-home exercise.",
        send_at: days_ago(3),
        status: "failed",
        error_reason: "SMTP timeout"
      }
    ]

    Enum.each(specs, fn spec ->
      conv = conv_for.(spec.email, spec.context) || conv_for.(spec.email, "general")

      if conv do
        sent_at = if spec.status == "sent", do: spec.send_at, else: nil
        failed_at = if spec.status == "failed", do: spec.send_at, else: nil

        %Treby.ScheduledMessages.ScheduledMessage{}
        |> Ecto.Changeset.change(%{
          tenant_id: tenant.id,
          sender_type: "recruiter",
          sender_id: users.admin.id,
          conversation_id: conv.id,
          body: spec.body,
          message_type: "text",
          send_at: spec.send_at,
          status: spec.status,
          sent_at: sent_at,
          failed_at: failed_at,
          error_reason: spec[:error_reason],
          retry_count: if(spec.status == "failed", do: 1, else: 0),
          created_by_id: users.admin.id,
          inserted_at: DateTime.add(spec.send_at, -1, :day),
          updated_at: spec.send_at
        })
        |> Repo.insert!()
      end
    end)

    IO.puts("  created #{length(specs)} scheduled messages")
  end

  # ------------------------------------------------------------------
  # Career page + custom fields + templates
  # ------------------------------------------------------------------

  defp create_career_page(tenant) do
    %Treby.Careers.CareerPage{}
    |> Ecto.Changeset.change(%{
      tenant_id: tenant.id,
      title: "Acme Corp Careers",
      description: "Join us in building the future!",
      about:
        "Acme Corp builds tools that help teams hire better. We are remote-first, design-driven, and obsessed with developer experience.",
      published: true
    })
    |> Repo.insert!()

    IO.puts("  career page published")
  end

  defp create_custom_fields(tenant, users) do
    fields = [
      %{name: "Portfolio URL", field_type: "url", applies_to: "candidate", position: 0},
      %{name: "Years of experience", field_type: "number", applies_to: "candidate", position: 1},
      %{name: "Team", field_type: "text", applies_to: "job", position: 0},
      %{
        name: "Referral source",
        field_type: "select",
        applies_to: "application",
        options: ["LinkedIn", "Referral", "Career page", "Agency"],
        position: 0
      }
    ]

    Enum.each(fields, fn attrs ->
      {:ok, _} =
        Treby.Customization.create_custom_field(
          Map.put(attrs, :tenant_id, tenant.id),
          users.admin
        )
    end)

    IO.puts("  created #{length(fields)} custom fields")
  end

  defp create_scorecard_template(tenant, users) do
    criteria = [
      %{"name" => "Technical skills", "type" => "number_1_5"},
      %{"name" => "Communication", "type" => "number_1_5"},
      %{"name" => "Problem solving", "type" => "number_1_5"},
      %{"name" => "Culture fit", "type" => "yes_no_maybe"}
    ]

    {:ok, _} =
      Treby.Scorecards.create_scorecard_template(
        %{
          "tenant_id" => tenant.id,
          "name" => "Engineering interview",
          "criteria" => criteria,
          "position" => 0
        },
        users.admin
      )

    IO.puts("  scorecard template created")
  end

  defp create_email_templates(tenant, users) do
    templates = [
      %{
        stage_type: "new",
        name: "Application received",
        subject: "We received your application, {candidate_name}!",
        body:
          "Hi {candidate_name},\n\nthanks for applying to {job_title} at {company_name}. We will review your profile and get back to you soon.\n\n— {company_name}"
      },
      %{
        stage_type: "interview",
        name: "Interview invitation",
        subject: "Interview for {job_title}",
        body:
          "Hi {candidate_name},\n\nwe would love to invite you to an interview for {job_title}. Please pick a slot in your portal.\n\n— {company_name}"
      },
      %{
        stage_type: "offer",
        name: "Offer",
        subject: "Your offer for {job_title}",
        body:
          "Hi {candidate_name},\n\ngreat news — we would like to extend an offer for {job_title}. Let's talk details.\n\n— {company_name}"
      },
      %{
        stage_type: "hired",
        name: "Welcome aboard",
        subject: "Welcome to {company_name}!",
        body:
          "Hi {candidate_name},\n\nwelcome aboard! We are thrilled to have you on the team.\n\n— {company_name}"
      },
      %{
        stage_type: "rejected",
        name: "Application update",
        subject: "Update on your application for {job_title}",
        body:
          "Hi {candidate_name},\n\nthank you for your interest in {job_title}. We have decided to move forward with other candidates.\n\n— {company_name}"
      }
    ]

    Enum.each(templates, fn attrs ->
      {:ok, _} =
        Treby.EmailTemplates.upsert_email_template(
          attrs
          |> Map.new(fn {k, v} -> {to_string(k), v} end)
          |> Map.put("tenant_id", tenant.id),
          users.admin
        )
    end)

    IO.puts("  created #{length(templates)} email templates")
  end

  # ------------------------------------------------------------------
  # Availability + calendar
  # ------------------------------------------------------------------

  defp create_availability(tenant, users) do
    Treby.Availability.seed_company_default_rules(tenant)

    Enum.each([users.admin, users.member, users.recruiter], fn user ->
      Treby.Availability.seed_user_from_company(user, tenant)
    end)

    IO.puts("  company + user availability rules created")
  end

  defp create_calendar_connection(tenant, users) do
    {:ok, _} =
      Treby.Calendar.connect_provider("google", users.admin.id, tenant.id, %{
        access_token: "demo-access-token",
        refresh_token: "demo-refresh-token",
        expires_at: days_ahead(1),
        email: "admin@acme.com"
      })

    IO.puts("  connected admin Google Calendar (demo)")
  end

  # ------------------------------------------------------------------
  # Webhooks
  # ------------------------------------------------------------------

  defp create_webhooks(tenant, _users) do
    sub =
      %Treby.Webhooks.WebhookSubscription{}
      |> Treby.Webhooks.WebhookSubscription.changeset(%{
        tenant_id: tenant.id,
        target_url: "https://hooks.example.com/treby/acme",
        events_text: "application.*, interview.scheduled, candidate.created",
        secret: "whsec_demo_acme_0123456789",
        active: true,
        description: "Sync new applications to our internal ATS dashboard"
      })
      |> Repo.insert!()

    logs = [
      %{
        action: "application.created",
        status: "success",
        attempts: 1,
        last_response: "HTTP 200",
        days: 0
      },
      %{
        action: "interview.scheduled",
        status: "success",
        attempts: 1,
        last_response: "HTTP 200",
        days: 1
      },
      %{
        action: "candidate.created",
        status: "failed",
        attempts: 3,
        last_response: "HTTP 500",
        days: 2
      },
      %{
        action: "application.stage_changed",
        status: "success",
        attempts: 2,
        last_response: "HTTP 200",
        days: 3
      },
      %{
        action: "application.created",
        status: "retrying",
        attempts: 2,
        last_response: "connection timeout",
        days: 0
      }
    ]

    Enum.each(logs, fn log ->
      %Treby.Webhooks.WebhookDeliveryLog{}
      |> Treby.Webhooks.WebhookDeliveryLog.changeset(%{
        tenant_id: tenant.id,
        subscription_id: sub.id,
        action: log.action,
        payload: %{"event" => log.action, "data" => %{}},
        status: log.status,
        attempts: log.attempts,
        last_response: log.last_response
      })
      |> Ecto.Changeset.change(%{inserted_at: days_ago(log.days)})
      |> Repo.insert!()
    end)

    IO.puts("  created 1 webhook subscription with #{length(logs)} deliveries")
  end

  # ------------------------------------------------------------------
  # Notifications inbox
  # ------------------------------------------------------------------

  defp create_notifications(tenant, users) do
    recipients = [users.admin, users.member, users.recruiter, users.hiring]

    specs = [
      %{
        type: "new_application",
        title: "New application: Eve Davis — Senior Elixir Developer",
        body: "Eve Davis applied for Senior Elixir Developer",
        link: "/app/candidates",
        days: 0,
        read: false
      },
      %{
        type: "interview_scheduled",
        title: "Interview scheduled: Bob Smith",
        body: "Interview for Senior Elixir Developer on Thursday",
        link: "/app/interviews",
        days: 0,
        read: false
      },
      %{
        type: "stage_change",
        title: "Stage change: Alice Johnson → Offer",
        body: "Alice Johnson moved from Interview to Offer",
        link: "/app/candidates",
        days: 1,
        read: false
      },
      %{
        type: "new_application",
        title: "New application: Frank Miller — Product Designer",
        body: "Frank Miller applied for Product Designer",
        link: "/app/candidates",
        days: 1,
        read: true
      },
      %{
        type: "stage_change",
        title: "Stage change: Nina Kowalski → Offer",
        body: "Nina Kowalski moved from Interview to Offer",
        link: "/app/candidates",
        days: 3,
        read: true
      },
      %{
        type: "interview_cancelled",
        title: "Interview cancelled: Omar Haddad",
        body: "The interview with Omar Haddad was cancelled",
        link: "/app/interviews",
        days: 5,
        read: true
      }
    ]

    count =
      Enum.reduce(recipients, 0, fn user, acc ->
        Enum.reduce(specs, acc, fn spec, inner ->
          %Treby.Notifications.Notification{}
          |> Ecto.Changeset.change(%{
            tenant_id: tenant.id,
            recipient_id: user.id,
            actor_id: users.admin.id,
            type: spec.type,
            title: spec.title,
            body: spec.body,
            link: spec.link,
            read_at: if(spec.read, do: days_ago(spec.days), else: nil),
            inserted_at: days_ago(spec.days),
            updated_at: days_ago(spec.days)
          })
          |> Repo.insert!()

          inner + 1
        end)
      end)

    IO.puts("  created #{count} inbox notifications")
  end

  # ------------------------------------------------------------------
  # Data privacy requests
  # ------------------------------------------------------------------

  defp create_data_privacy_requests(tenant, users) do
    %Treby.DataPrivacy.DataPrivacyRequest{}
    |> Treby.DataPrivacy.DataPrivacyRequest.changeset(%{
      tenant_id: tenant.id,
      requester_id: users.admin.id,
      type: "export",
      scope: "tenant",
      status: "ready",
      s3_key: "exports/acme-#{Ecto.UUID.generate()}.zip",
      expires_at: days_ahead(5),
      metadata: %{"size_bytes" => 2_480_112}
    })
    |> Ecto.Changeset.change(%{inserted_at: days_ago(2), updated_at: days_ago(1)})
    |> Repo.insert!()

    %Treby.DataPrivacy.DataPrivacyRequest{}
    |> Treby.DataPrivacy.DataPrivacyRequest.changeset(%{
      tenant_id: tenant.id,
      requester_id: users.admin.id,
      type: "export",
      scope: "user",
      status: "completed",
      s3_key: "exports/admin-#{Ecto.UUID.generate()}.zip",
      expires_at: days_ago(1),
      completed_at: days_ago(8),
      metadata: %{"size_bytes" => 51_200}
    })
    |> Ecto.Changeset.change(%{inserted_at: days_ago(9), updated_at: days_ago(8)})
    |> Repo.insert!()

    IO.puts("  created data privacy requests")
  end

  # ------------------------------------------------------------------
  # AI assistant conversation
  # ------------------------------------------------------------------

  defp create_ai_conversation(tenant, users) do
    {:ok, conv} =
      %Treby.AI.Conversation{}
      |> Treby.AI.Conversation.changeset(%{
        tenant_id: tenant.id,
        user_id: users.admin.id,
        title: "Pipeline overview",
        status: "active",
        session_token: nil
      })
      |> Repo.insert()

    Treby.AI.Conversations.create_message(conv, %{
      role: "user",
      content: "How is our Senior Elixir Developer pipeline looking?"
    })

    Treby.AI.Conversations.create_message(conv, %{
      role: "assistant",
      content:
        "The Senior Elixir Developer role has 8 applications: 3 are interviewing, 1 is at the offer stage, 1 was hired, 1 rejected, and 2 are still in early screening. Screening is the slowest stage at the moment."
    })

    IO.puts("  created AI assistant conversation")
  end

  # ------------------------------------------------------------------
  # Job views (job analytics)
  # ------------------------------------------------------------------

  defp create_job_views(tenant, jobs) do
    sources = ["linkedin", "indeed", "google", "referral", nil]

    {total, _} =
      jobs
      |> Enum.reduce({0, 0}, fn {_title, job}, {total, seed} ->
        views = if job.status == "open", do: 140, else: 25

        Enum.reduce(1..views, {total, seed}, fn i, {t, s} ->
          days = rem(s * 7 + i, 30)
          source = Enum.at(sources, rem(s + i, length(sources)))

          result =
            Treby.JobViews.track_view(%{
              job_id: job.id,
              tenant_id: tenant.id,
              session_hash: "seed-#{job.id}-#{s}-#{i}",
              viewed_at: days_ago(days) |> DateTime.add(rem(i, 12), :hour),
              referer: source && "https://#{source}.com",
              utm_source: source,
              user_agent: "Mozilla/5.0 (seed)"
            })

          {t + if(match?({:ok, _}, result), do: 1, else: 0), s + 1}
        end)
      end)

    IO.puts("  recorded #{total} job views")
  end

  # ------------------------------------------------------------------
  # Audit log
  # ------------------------------------------------------------------

  defp create_audit_events(tenant, users, jobs, candidates, _applications) do
    specs = [
      %{
        action: "job.created",
        entity_type: "job",
        entity_id: jobs["Senior Elixir Developer"].id,
        days: 6
      },
      %{
        action: "job.created",
        entity_type: "job",
        entity_id: jobs["Product Designer"].id,
        days: 24
      },
      %{
        action: "job.updated",
        entity_type: "job",
        entity_id: jobs["DevOps Engineer"].id,
        days: 5
      },
      %{action: "job.closed", entity_type: "job", entity_id: jobs["Data Analyst"].id, days: 30},
      %{
        action: "candidate.created",
        entity_type: "candidate",
        entity_id: candidates["alice@example.com"].id,
        days: 42
      },
      %{
        action: "candidate.updated",
        entity_type: "candidate",
        entity_id: candidates["alice@example.com"].id,
        days: 12
      },
      %{
        action: "candidate.merged",
        entity_type: "candidate",
        entity_id: candidates["grace.hopper@gmail.com"].id,
        days: 15
      },
      %{
        action: "application.created",
        entity_type: "application",
        entity_id: Ecto.UUID.generate(),
        days: 2
      },
      %{
        action: "application.stage_changed",
        entity_type: "application",
        entity_id: Ecto.UUID.generate(),
        days: 10
      },
      %{
        action: "application.rejected",
        entity_type: "application",
        entity_id: Ecto.UUID.generate(),
        days: 9
      },
      %{
        action: "interview.scheduled",
        entity_type: "interview_event",
        entity_id: Ecto.UUID.generate(),
        days: 3
      },
      %{
        action: "interview.completed",
        entity_type: "interview_event",
        entity_id: Ecto.UUID.generate(),
        days: 6
      },
      %{
        action: "scorecard.submitted",
        entity_type: "scorecard",
        entity_id: Ecto.UUID.generate(),
        days: 6
      },
      %{
        action: "custom_field.created",
        entity_type: "custom_field",
        entity_id: Ecto.UUID.generate(),
        days: 20
      },
      %{
        action: "email_template.updated",
        entity_type: "email_template",
        entity_id: Ecto.UUID.generate(),
        days: 18
      },
      %{
        action: "webhook_subscription.created",
        entity_type: "webhook_subscription",
        entity_id: Ecto.UUID.generate(),
        days: 14
      },
      %{
        action: "member.invited",
        entity_type: "membership",
        entity_id: Ecto.UUID.generate(),
        days: 27
      },
      %{action: "settings.updated", entity_type: "tenant", entity_id: tenant.id, days: 4},
      %{
        action: "data_privacy.export_requested",
        entity_type: "data_privacy_request",
        entity_id: Ecto.UUID.generate(),
        days: 2
      }
    ]

    Enum.each(specs, fn spec ->
      actor = Enum.random(Map.values(users))

      %Treby.Audit.AuditEvent{}
      |> Treby.Audit.AuditEvent.changeset(%{
        tenant_id: tenant.id,
        actor_id: actor.id,
        actor_type: "user",
        action: spec.action,
        entity_type: spec.entity_type,
        entity_id: spec.entity_id,
        metadata: %{"after" => %{"source" => "seed"}},
        ip: "203.0.113.#{Enum.random(1..250)}"
      })
      |> Ecto.Changeset.change(%{inserted_at: days_ago(spec.days)})
      |> Repo.insert!()
    end)

    IO.puts("  created #{length(specs)} audit events")
  end

  # ------------------------------------------------------------------
  # Dashboard activity feed
  # ------------------------------------------------------------------

  defp create_tenant_activities(tenant, users, candidates, _applications) do
    specs = [
      %{
        action: "new_application",
        candidate: "Eve Davis",
        job: "Senior Elixir Developer",
        days: 2
      },
      %{action: "new_application", candidate: "Frank Miller", job: "Product Designer", days: 1},
      %{
        action: "application_stage_changed",
        candidate: "Alice Johnson",
        job: "Senior Elixir Developer",
        days: 10
      },
      %{
        action: "interview_scheduled",
        candidate: "Bob Smith",
        job: "Senior Elixir Developer",
        days: 3
      },
      %{
        action: "candidates_merged",
        candidate: "Grace Hopper",
        job: "Product Designer",
        days: 15
      },
      %{action: "candidate_created", candidate: "Omar Haddad", job: "Data Analyst", days: 35}
    ]

    Enum.each(specs, fn spec ->
      candidate =
        Enum.find(candidates, fn {_email, c} -> c.name == spec.candidate end) |> elem(1)

      %Treby.Activities.ActivityLog{}
      |> Ecto.Changeset.change(%{
        action: spec.action,
        entity_type: "candidate",
        entity_id: candidate.id,
        tenant_id: tenant.id,
        actor_id: users.admin.id,
        metadata: %{
          "candidate_name" => spec.candidate,
          "job_title" => spec.job,
          "new_stage" => "Offer"
        },
        inserted_at: days_ago(spec.days),
        updated_at: days_ago(spec.days)
      })
      |> Repo.insert!()
    end)
  end

  # ------------------------------------------------------------------
  # Beta workspace for workspace switching
  # ------------------------------------------------------------------

  defp create_beta_workspace do
    beta =
      %Treby.Tenants.Tenant{}
      |> Treby.Tenants.Tenant.changeset(%{name: "Beta Corp", slug: "beta", timezone: "UTC"})
      |> Repo.insert!()

    Treby.Pipeline.create_default_pipeline_stages(beta)

    beta_job =
      Ecto.build_assoc(beta, :jobs)
      |> Treby.Jobs.Job.changeset(%{
        title: "Marketing Lead",
        description: "Lead our marketing efforts across Europe.",
        salary_range: "€60k-€80k",
        location: "Amsterdam, Netherlands",
        employment_type: "full_time",
        workplace_type: "hybrid"
      })
      |> Repo.insert!()

    _ = beta_job

    user =
      Ecto.build_assoc(beta, :users)
      |> Treby.Accounts.User.changeset(%{
        email: "multi@demo.com",
        password: @password,
        name: "Multi Demo",
        role: "admin"
      })
      |> Repo.insert!()

    {:ok, _} =
      Treby.Memberships.create_membership(%{user_id: user.id, tenant_id: beta.id, role: "admin"})

    acme = Treby.Tenants.get_tenant_by_slug("acme")

    {:ok, _} =
      Treby.Memberships.create_membership(%{user_id: user.id, tenant_id: acme.id, role: "member"})

    IO.puts("  created Beta workspace + multi@demo.com")
  end
end

Treby.Seeds.run()
