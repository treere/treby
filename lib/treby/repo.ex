defmodule Treby.Repo do
  use Ecto.Repo,
    otp_app: :treby,
    adapter: Ecto.Adapters.Postgres

  require Ecto.Query

  @tenant_key {__MODULE__, :tenant_id}

  @doc "Stores the current tenant id in the process dictionary."
  def put_tenant_id(tenant_id) do
    Process.put(@tenant_key, tenant_id)
  end

  @doc "Reads the current tenant id from the process dictionary."
  def get_tenant_id do
    Process.get(@tenant_key)
  end

  @doc """
  Establishes the process tenant from a session map (candidate flows).
  No session tenant means pre-login: leaves the dictionary untouched.
  """
  def put_tenant_id_from_session(session, key \\ "candidate_tenant_id") do
    case session[key] do
      nil -> :ok
      tenant_id -> put_tenant_id(tenant_id)
    end
  end

  @impl true
  def default_options(_operation) do
    [tenant_id: get_tenant_id()]
  end

  @impl true
  def prepare_query(_operation, query, opts) do
    cond do
      opts[:skip_tenant_id] || opts[:ecto_query] in [:schema_migration, :preload] ->
        {query, opts}

      not tenant_field?(query) ->
        {query, opts}

      tenant = opts[:tenant_id] || get_tenant_id() ->
        {scope_to_tenant(query, tenant), opts}

      true ->
        raise "expected tenant_id or skip_tenant_id to be set for #{inspect(queryable(query))}"
    end
  end

  defp scope_to_tenant(query, tenant) do
    Ecto.Query.where(query, tenant_id: ^tenant)
  end

  defp tenant_field?(%Ecto.Query{} = query) do
    case queryable(query) do
      nil -> false
      schema -> :tenant_id in schema.__schema__(:fields)
    end
  end

  defp tenant_field?(_), do: false

  defp queryable(%Ecto.Query{from: %{source: {_table, schema}}})
       when is_atom(schema) and not is_nil(schema) do
    if function_exported?(schema, :__schema__, 1), do: schema, else: nil
  end

  defp queryable(_), do: nil
end
