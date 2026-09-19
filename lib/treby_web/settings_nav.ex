defmodule TrebyWeb.SettingsNav do
  @moduledoc """
  Static navigation config for the settings sidebar.

  Groups and items are ordered semantically. Each item carries
  title, subtitle, icon, path suffix, required role, and a stable DOM id.
  """

  @groups [
    %{
      id: :organization,
      label: "Organization",
      icon: "hero-building-office",
      items: [
        %{
          key: :team,
          label: "Team",
          subtitle: "Manage team members and invites",
          icon: "hero-users",
          path: "/settings/team",
          role: :admin,
          dom_id: "settings-nav-team"
        },
        %{
          key: :branding,
          label: "Branding",
          subtitle: "Customize career page appearance",
          icon: "hero-paint-brush",
          path: "/settings/branding",
          role: :admin,
          dom_id: "settings-nav-branding"
        },
        %{
          key: :company_availability,
          label: "Company Availability",
          subtitle: "Default hours for new team members",
          icon: "hero-clock",
          path: "/settings/company-availability",
          role: :admin,
          dom_id: "settings-nav-company-availability"
        }
      ]
    },
    %{
      id: :hiring_process,
      label: "Hiring Process",
      icon: "hero-adjustments-horizontal",
      items: [
        %{
          key: :pipeline,
          label: "Pipeline Stages",
          subtitle: "Customize your hiring pipeline stages",
          icon: "hero-rectangle-stack",
          path: "/settings/pipeline",
          role: :admin,
          dom_id: "settings-nav-pipeline"
        },
        %{
          key: :fields,
          label: "Custom Fields",
          subtitle: "Define custom fields for candidates and jobs",
          icon: "hero-list-bullet",
          path: "/settings/fields",
          role: :admin,
          dom_id: "settings-nav-fields"
        },
        %{
          key: :scorecards,
          label: "Scorecard Templates",
          subtitle: "Define evaluation criteria for interviews",
          icon: "hero-clipboard-document-check",
          path: "/settings/scorecards",
          role: :admin,
          dom_id: "settings-nav-scorecards"
        }
      ]
    },
    %{
      id: :communication,
      label: "Communication",
      icon: "hero-chat-bubble-left-right",
      items: [
        %{
          key: :email_templates,
          label: "Message Templates",
          subtitle: "Configure message templates for stage transitions",
          icon: "hero-envelope",
          path: "/settings/emails",
          role: :admin,
          dom_id: "settings-nav-emails"
        },
        %{
          key: :notifications,
          label: "Notifications",
          subtitle: "Configure automated email notifications",
          icon: "hero-bell",
          path: "/settings/notifications",
          role: :admin,
          dom_id: "settings-nav-notifications"
        },
        %{
          key: :webhooks,
          label: "Webhooks",
          subtitle: "Send events to external systems",
          icon: "hero-link",
          path: "/settings/webhooks",
          role: :admin,
          dom_id: "settings-nav-webhooks"
        },
        %{
          key: :messages_queue,
          label: "Message Queue",
          subtitle: "Scheduled, sent and failed messages",
          icon: "hero-queue-list",
          path: "/messages-queue",
          role: :admin,
          dom_id: "settings-nav-message-queue"
        }
      ]
    },
    %{
      id: :scheduling,
      label: "Scheduling",
      icon: "hero-calendar-days",
      items: [
        %{
          key: :calendar,
          label: "Calendar",
          subtitle: "Connect Google Calendar for scheduling",
          icon: "hero-calendar",
          path: "/settings/calendar",
          role: :member,
          dom_id: "settings-nav-calendar"
        },
        %{
          key: :availability,
          label: "My Availability",
          subtitle: "Set your available hours for interviews",
          icon: "hero-clock",
          path: "/settings/availability",
          role: :member,
          dom_id: "settings-nav-availability"
        }
      ]
    },
    %{
      id: :privacy_system,
      label: "Privacy & System",
      icon: "hero-shield-check",
      items: [
        %{
          key: :audit_log,
          label: "Audit Log",
          subtitle: "Immutable history of changes",
          icon: "hero-document-text",
          path: "/settings/audit-log",
          role: :admin,
          dom_id: "settings-nav-audit-log"
        },
        %{
          key: :data_privacy,
          label: "Data & Privacy",
          subtitle: "Data export and erasure requests",
          icon: "hero-lock-closed",
          path: "/settings/data-privacy",
          role: :member,
          dom_id: "settings-nav-data-privacy"
        },
        %{
          key: :language,
          label: "Language",
          subtitle: "Set your preferred language",
          icon: "hero-language",
          path: "/settings/language",
          role: :member,
          dom_id: "settings-nav-language"
        }
      ]
    }
  ]

  def groups, do: @groups

  def all_items do
    Enum.flat_map(@groups, & &1.items)
  end

  def groups_for_role(role) when role in [:admin, "admin"] do
    @groups
  end

  def groups_for_role(_role) do
    @groups
    |> Enum.map(fn group ->
      items = Enum.filter(group.items, &(&1.role == :member))
      # Data & Privacy personal entry: members see it even though admin-gated;
      # we expose it via the same path but allow navigation — the page itself
      # handles personal vs admin view.
      items =
        if group.id == :privacy_system do
          # Ensure Data & Privacy shows for members as "Manage my data"
          data_privacy = Enum.find(all_items(), &(&1.key == :data_privacy))

          if data_privacy && !Enum.any?(items, &(&1.key == :data_privacy)) do
            items ++ [%{data_privacy | subtitle: "Manage my data"}]
          else
            items
          end
        else
          items
        end

      %{group | items: items}
    end)
    |> Enum.reject(&(&1.items == []))
  end

  def path_with_tenant(path, nil), do: "/app" <> path
  def path_with_tenant(path, %{slug: slug}) when is_binary(slug), do: "/#{slug}/app" <> path
  def path_with_tenant(path, _), do: "/app" <> path
end
