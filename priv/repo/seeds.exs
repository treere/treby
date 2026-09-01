# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Treby.Repo.insert!(%Treby.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Treby.Repo
import Ecto.Query, only: [from: 2]

# Create demo tenant
tenant =
  %Treby.Tenants.Tenant{}
  |> Treby.Tenants.Tenant.changeset(%{name: "Acme Corp", slug: "acme"})
  |> Repo.insert!()

IO.puts("Created tenant: #{tenant.name}")

# Create default pipeline stages
Treby.Pipeline.create_default_pipeline_stages(tenant)

# Create admin user
admin =
  Ecto.build_assoc(tenant, :users)
  |> Treby.Accounts.User.changeset(%{
    email: "admin@acme.com",
    password: "password123",
    name: "Admin User",
    role: "admin"
  })
  |> Repo.insert!()

{:ok, _} =
  Treby.Memberships.create_membership(%{user_id: admin.id, tenant_id: tenant.id, role: "admin"})

IO.puts("Created admin user: #{admin.email}")

# Create team member
member =
  Ecto.build_assoc(tenant, :users)
  |> Treby.Accounts.User.changeset(%{
    email: "member@acme.com",
    password: "password123",
    name: "Team Member",
    role: "member"
  })
  |> Repo.insert!()

{:ok, _} =
  Treby.Memberships.create_membership(%{user_id: member.id, tenant_id: tenant.id, role: "member"})

IO.puts("Created member user: #{member.email}")

# Create jobs
jobs =
  [
    %{
      title: "Senior Elixir Developer",
      description:
        "We're looking for an experienced Elixir developer to join our team. You'll work on building scalable, fault-tolerant systems.",
      salary_range: "$120k-$160k"
    },
    %{
      title: "Product Designer",
      description:
        "Join our design team to create beautiful, intuitive user experiences. Experience with Figma and design systems required.",
      salary_range: "$100k-$140k"
    },
    %{
      title: "DevOps Engineer",
      description:
        "Help us build and maintain our infrastructure. Experience with AWS, Docker, and Kubernetes preferred.",
      salary_range: "$110k-$150k"
    }
  ]
  |> Enum.map(fn job_attrs ->
    job =
      Ecto.build_assoc(tenant, :jobs)
      |> Treby.Jobs.Job.changeset(job_attrs)
      |> Repo.insert!()

    IO.puts("Created job: #{job.title}")
    job
  end)

# Get pipeline stages
pipeline_id = Treby.Pipeline.default_pipeline_id(tenant.id)
stages = Treby.Pipeline.list_pipeline_stages(pipeline_id)
first_stage = List.first(stages)

# Create candidates
candidates =
  [
    %{name: "Alice Johnson", email: "alice@example.com", phone: "555-0101"},
    %{name: "Bob Smith", email: "bob@example.com", phone: "555-0102"},
    %{name: "Carol Williams", email: "carol@example.com", phone: "555-0103"},
    %{name: "David Brown", email: "david@example.com", phone: "555-0104"},
    %{name: "Eve Davis", email: "eve@example.com", phone: "555-0105"}
  ]
  |> Enum.map(fn candidate_attrs ->
    candidate =
      Ecto.build_assoc(tenant, :candidates)
      |> Treby.Candidates.Candidate.changeset(candidate_attrs)
      |> Repo.insert!()

    IO.puts("Created candidate: #{candidate.name}")
    candidate
  end)

# Create applications
Enum.with_index(candidates, 1)
|> Enum.each(fn {candidate, index} ->
  job =
    if index == 1 do
      Enum.at(jobs, 0)
    else
      Enum.random(jobs)
    end

  application =
    Ecto.build_assoc(tenant, :applications)
    |> Ecto.Changeset.change(%{
      job_id: job.id,
      candidate_id: candidate.id,
      pipeline_stage_id: first_stage.id,
      applied_at: DateTime.utc_now() |> DateTime.truncate(:second)
    })
    |> Repo.insert!()

  IO.puts("Created application: #{candidate.name} for #{job.title}")
end)

# Give Alice a concurrent application in a second position so pipeline
# cards show the "Also in N other positions" indicator.
alice = Enum.at(candidates, 0)
second_job = Enum.at(jobs, 1)

Ecto.build_assoc(tenant, :applications)
|> Ecto.Changeset.change(%{
  job_id: second_job.id,
  candidate_id: alice.id,
  pipeline_stage_id: first_stage.id,
  applied_at: DateTime.utc_now() |> DateTime.truncate(:second)
})
|> Repo.insert!()

IO.puts("Created second application: #{alice.name} for #{second_job.title}")

# Duplicate candidates to exercise the merge center
duplicates =
  [
    %{name: "Frank Miller", email: "frank@example.com", phone: "555-0120"},
    %{name: "Frank M.", email: "frank@example.com", phone: "555-0121"},
    %{name: "Grace Hopper", email: "grace.hopper@company.com", phone: "555-0122"},
    %{name: "Grace Hopper", email: "grace.hopper@gmail.com", phone: "+39 555-0122"},
    %{name: "Heidi Lee", email: "heidi.lee@acme.com", phone: "555-0123"},
    %{name: "Heidi Lee", email: "heidi.lee@outlook.com", phone: "555-0124"}
  ]
  |> Enum.map(fn candidate_attrs ->
    candidate =
      Ecto.build_assoc(tenant, :candidates)
      |> Treby.Candidates.Candidate.changeset(candidate_attrs)
      |> Repo.insert!()

    IO.puts("Created duplicate candidate: #{candidate.name}")
    candidate
  end)

Enum.each(duplicates, fn candidate ->
  job = Enum.random(jobs)

  Ecto.build_assoc(tenant, :applications)
  |> Ecto.Changeset.change(%{
    job_id: job.id,
    candidate_id: candidate.id,
    pipeline_stage_id: first_stage.id,
    applied_at: DateTime.utc_now() |> DateTime.truncate(:second)
  })
  |> Repo.insert!()
end)

# Create career page
%Treby.Careers.CareerPage{}
|> Ecto.Changeset.change(%{
  tenant_id: tenant.id,
  title: "Acme Corp Careers",
  description: "Join us in building the future!",
  published: true,
  primary_color: "#2563EB"
})
|> Repo.insert!()

IO.puts("Created career page for #{tenant.name}")

# Create sample scheduled messages for the message queue (portal)
later_1 = DateTime.utc_now() |> DateTime.add(3600, :second) |> DateTime.truncate(:second)
later_2 = DateTime.utc_now() |> DateTime.add(7200, :second) |> DateTime.truncate(:second)
later_3 = DateTime.utc_now() |> DateTime.add(10800, :second) |> DateTime.truncate(:second)

Enum.each(
  [
    %{
      email: "alice@example.com",
      body: "Hi Alice, we'd love to invite you to an interview.",
      send_at: later_1
    },
    %{
      email: "bob@example.com",
      body: "Hi Bob, just following up on your application status.",
      send_at: later_2
    },
    %{
      email: "carol@example.com",
      body: "Hi Carol, your application is moving forward.",
      send_at: later_3
    }
  ],
  fn %{email: email, body: body, send_at: send_at} ->
    candidate = Repo.get_by!(Treby.Candidates.Candidate, tenant_id: tenant.id, email: email)

    application =
      Repo.one(
        from a in Treby.Pipeline.Application,
          where: a.candidate_id == ^candidate.id and a.tenant_id == ^tenant.id,
          order_by: [asc: a.inserted_at],
          limit: 1
      )

    conversation =
      case Treby.CandidatePortal.list_conversations_for_application(application.id, tenant.id)
           |> Enum.find(&(&1.context == "application")) do
        nil ->
          {:ok, conv} =
            Treby.CandidatePortal.create_conversation(%{
              candidate_id: candidate.id,
              tenant_id: tenant.id,
              application_id: application.id,
              subject: String.slice(body, 0, 80),
              context: "application"
            })

          conv

        conv ->
          conv
      end

    {:ok, scheduled_message} =
      Treby.ScheduledMessages.create_scheduled_message(%{
        tenant_id: tenant.id,
        sender_type: "recruiter",
        sender_id: admin.id,
        conversation_id: conversation.id,
        body: body,
        message_type: "text",
        send_at: send_at,
        created_by_id: admin.id
      })

    IO.puts("Scheduled message: #{scheduled_message.body}")
  end
)

IO.puts("\nSeed data created successfully!")
IO.puts("Login with: admin@acme.com / password123")
IO.puts("Career page: /acme/careers")
