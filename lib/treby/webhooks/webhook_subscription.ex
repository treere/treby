defmodule Treby.Webhooks.WebhookSubscription do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  @foreign_key_type :binary_id

  schema "webhook_subscriptions" do
    field :target_url, :string
    field :events, {:array, :string}, default: []
    field :secret, Treby.Encrypted.Binary
    field :active, :boolean, default: true
    field :description, :string, default: ""
    field :events_text, :string, virtual: true

    belongs_to :tenant, Treby.Tenants.Tenant

    timestamps(type: :utc_datetime)
  end

  @https_regex ~r/^https:\/\/.+/i

  def changeset(%{__meta__: %{state: :built}} = subscription, attrs) do
    subscription
    |> base_changeset(attrs)
    |> validate_required([:secret])
  end

  def changeset(subscription, attrs) do
    base_changeset(subscription, attrs)
  end

  defp base_changeset(subscription, attrs) do
    subscription
    |> cast(attrs, [:tenant_id, :target_url, :secret, :active, :description, :events_text])
    |> put_events_from_text()
    |> validate_format(:target_url, @https_regex, message: "must be a valid https:// URL")
    |> validate_active_events()
  end

  defp put_events_from_text(changeset) do
    text = get_field(changeset, :events_text)

    events =
      (text || "")
      |> String.split(~r/[,\s]+/, trim: true)
      |> Enum.reject(&(&1 == ""))
      |> Enum.uniq()

    put_change(changeset, :events, events)
  end

  defp validate_active_events(changeset) do
    if get_change(changeset, :active) == false do
      changeset
    else
      case get_field(changeset, :events) do
        events when is_list(events) and events != [] ->
          validate_each_event(changeset, events)

        _ ->
          add_error(changeset, :events_text, "must list at least one event when active")
      end
    end
  end

  defp validate_each_event(changeset, events) do
    if Enum.all?(events, &(is_binary(&1) and String.trim(&1) != "")) do
      changeset
    else
      add_error(changeset, :events_text, "must be a comma-separated list of event patterns")
    end
  end
end
