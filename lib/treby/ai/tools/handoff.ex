defmodule Treby.AI.Tools.Handoff do
  @moduledoc "Shared tool: switch the active agent domain for the next turn."

  alias Treby.AI.{Profiles, Session}

  def name, do: "handoff"

  def description,
    do:
      "Switch to a different specialized agent (recruiter, analytics, comms, admin) for the rest of the conversation."

  def destructive?, do: false

  def schema do
    %{
      "type" => "object",
      "properties" => %{
        "domain" => %{
          "type" => "string",
          "enum" => ["recruiter", "analytics", "comms", "admin"]
        }
      },
      "required" => ["domain"]
    }
  end

  def run(args, ctx) do
    domain = String.to_existing_atom(args["domain"])

    if domain in Profiles.domains() do
      Session.set_domain(ctx[:tenant_id], ctx[:user] && ctx[:user].id, domain)
      {:ok, %{"domain" => args["domain"], "switched" => true}}
    else
      {:error, "unknown domain"}
    end
  rescue
    ArgumentError -> {:error, "unknown domain"}
  end
end
