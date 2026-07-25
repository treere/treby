defmodule Treby.Scorecards.ScorecardTemplate do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "scorecard_templates" do
    field :name, :string
    field :criteria, Treby.Ecto.JSON, default: []
    field :position, :integer, default: 0
    belongs_to :tenant, Treby.Tenants.Tenant

    timestamps(type: :utc_datetime)
  end

  def changeset(scorecard_template, attrs) do
    scorecard_template
    |> cast(attrs, [:name, :criteria, :position])
    |> validate_required([:name, :criteria])
    |> validate_criteria()
  end

  defp validate_criteria(changeset) do
    case get_change(changeset, :criteria) do
      nil ->
        changeset

      criteria when is_list(criteria) ->
        valid_types = ~w(number_1_5 yes_no_maybe text)

        Enum.with_index(criteria)
        |> Enum.reduce(changeset, fn {criterion, idx}, acc ->
          cond do
            not is_binary(criterion["name"]) or criterion["name"] == "" ->
              add_error(acc, :criteria, "criterion at position %{pos} must have a name",
                pos: idx + 1
              )

            criterion["type"] not in valid_types ->
              add_error(acc, :criteria, "criterion at position %{pos} has invalid type",
                pos: idx + 1
              )

            true ->
              acc
          end
        end)

      _ ->
        add_error(changeset, :criteria, "must be a list of criteria")
    end
  end
end
