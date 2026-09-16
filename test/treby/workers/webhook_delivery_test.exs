defmodule Treby.Workers.WebhookDeliveryTest do
  use Treby.DataCase, async: true

  alias Treby.{Webhooks, Tenants, Repo}
  alias Treby.Workers.WebhookDelivery

  defp setup_tenant do
    {:ok, tenant} =
      Tenants.create_tenant(%{
        name: "WHW Corp #{System.unique_integer([:positive])}",
        slug: "whw-#{System.unique_integer([:positive])}"
      })

    tenant
  end

  describe "perform/1" do
    test "discards when the audit event no longer exists" do
      tenant = setup_tenant()

      job = %Oban.Job{
        args: %{audit_event_id: Ecto.UUID.generate(), tenant_id: tenant.id},
        attempt: 1,
        max_attempts: 5,
        worker: "Treby.Workers.WebhookDelivery"
      }

      assert {:discard, _} = WebhookDelivery.perform(job)
    end
  end

  describe "Webhooks.test_ping/2" do
    test "rejects non-https URLs without making a request" do
      assert {:error, "URL must start with https://"} =
               Webhooks.test_ping("http://insecure.test/h", "secret")
    end

    test "rejects invalid url/secret arguments" do
      assert {:error, "invalid url or secret"} = Webhooks.test_ping(nil, nil)
    end
  end
end
