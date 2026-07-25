defmodule Treby.CsvImport.ImportLog do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "import_logs" do
    field :file_name, :string
    field :imported_count, :integer, default: 0
    field :skipped_count, :integer, default: 0
    field :error_count, :integer, default: 0

    belongs_to :tenant, Treby.Tenants.Tenant
    belongs_to :user, Treby.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(import_log, attrs) do
    import_log
    |> cast(attrs, [
      :file_name,
      :imported_count,
      :skipped_count,
      :error_count,
      :tenant_id,
      :user_id
    ])
    |> validate_required([:file_name, :tenant_id])
  end
end
