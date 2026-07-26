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
Enum.each(candidates, fn candidate ->
  job = Enum.random(jobs)

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

IO.puts("\nSeed data created successfully!")
IO.puts("Login with: admin@acme.com / password123")
IO.puts("Career page: /acme/careers")
