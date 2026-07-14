# Tenant ID Pattern

Every table in Treby includes a `tenant_id` column to ensure data isolation between tenants.

## Schema Pattern

```elixir
defmodule Treby.SomeEntity do
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "some_entities" do
    # ... fields ...
    belongs_to :tenant, Treby.Tenants.Tenant

    timestamps(type: :utc_datetime)
  end
end
```

## Migration Pattern

```elixir
create table(:some_entities, primary_key: false) do
  add :id, :binary_id, primary_key: true
  # ... fields ...
  add :tenant_id, references(:tenants, type: :binary_id, on_delete: :delete_all), null: false

  timestamps(type: :utc_datetime)
end

create index(:some_entities, [:tenant_id])
```

## Context Pattern

Always pass `tenant` or `tenant_id` as the first argument to context functions:

```elixir
defmodule Treby.SomeContext do
  import Ecto.Query, warn: false
  alias Treby.Repo
  alias Treby.SomeEntity

  def list_entities(tenant_id) do
    SomeEntity
    |> where([e], e.tenant_id == ^tenant_id)
    |> Repo.all()
  end

  def get_entity!(tenant_id, id) do
    SomeEntity
    |> where([e], e.tenant_id == ^tenant_id and e.id == ^id)
    |> Repo.one!()
  end

  def create_entity(tenant_id, attrs) do
    %SomeEntity{}
    |> SomeEntity.changeset(Map.put(attrs, :tenant_id, tenant_id))
    |> Repo.insert()
  end
end
```

## LiveView Pattern

In LiveViews, the current tenant is available as `@current_tenant`:

```elixir
def mount(_params, session, socket) do
  tenant = get_tenant_from_session(session)
  {:ok, assign(socket, :current_tenant, tenant)}
end
```

## Router Pattern

For authenticated routes, the tenant scoping plug assigns `@current_tenant`:

```elixir
pipeline :require_auth do
  plug TrebyWeb.Plugs.Auth
end

scope "/app" do
  pipe_through [:browser, :require_auth]

  live "/jobs", JobsLive.Index
end
```

For public career pages, the tenant is extracted from the URL slug:

```elixir
scope "/:tenant_slug" do
  pipe_through :browser

  live "/careers", CareersLive.Index
end
```
