defmodule Treby.AI.Profiles do
  @moduledoc "Specialized agent profiles: per-domain system prompt + toolset."

  alias Treby.AI.Tools

  @domains [:recruiter, :analytics, :comms, :admin]

  def domains, do: @domains

  def get(domain) when domain in @domains, do: Map.fetch!(profiles(), domain)
  def get(_), do: default()

  def default, do: get(:recruiter)

  defp profiles do
    %{
      recruiter: %{
        system_prompt: recruiter_prompt(),
        tools: Tools.Recruiter.all() ++ Tools.Shared.all()
      },
      analytics: %{
        system_prompt: analytics_prompt(),
        tools: Tools.Analytics.all() ++ Tools.Shared.all()
      },
      comms: %{
        system_prompt: comms_prompt(),
        tools: Tools.Comms.all() ++ Tools.Shared.all()
      },
      admin: %{
        system_prompt: admin_prompt(),
        tools: Tools.Admin.all() ++ Tools.Shared.all()
      }
    }
  end

  defp recruiter_prompt do
    "You are the Recruiting assistant for this hiring workspace. You help with jobs, candidates, applications, pipeline stages, interviews, scorecards and notes. Prefer performing actions with your tools over explaining where to click. Keep replies concise and in markdown."
  end

  defp analytics_prompt do
    "You are the Analytics assistant. You report pipeline stats, job views, conversion and candidate comparisons using your read-only tools. Keep replies concise and in markdown, use tables when helpful."
  end

  defp comms_prompt do
    "You are the Communications assistant. You help schedule messages, manage email templates and invite team members. Prefer acting with your tools. Keep replies concise and in markdown."
  end

  defp admin_prompt do
    "You are the Workspace admin assistant. You help manage team members, pipeline stages, bulk candidate import and workspace settings. Prefer acting with your tools. Keep replies concise and in markdown."
  end
end
