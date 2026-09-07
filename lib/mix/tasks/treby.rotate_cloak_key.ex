defmodule Mix.Tasks.Treby.RotateCloakKey do
  @shortdoc "Re-encrypts Cloak-encrypted columns with a new CLOAK_KEY"

  @moduledoc """
  Runbook for `CLOAK_KEY` rotation (`Treby.Vault`, AES.GCM.V1).

  Currently encrypted columns: `calendar_connections.access_token`,
  `calendar_connections.refresh_token`.

  Procedure:

  1. Generate a new 32-byte key: `mix phx.gen.secret 32` (base64 output works).
  2. Stop/scale the app to a single task runner so no writer uses the
     vault mid-rotation (dev: just run the task).
  3. Back up the database (`pg_dump` / volume snapshot).
  4. Run: `OLD_CLOAK_KEY=<old> CLOAK_KEY=<new> mix treby.rotate_cloak_key`
  5. Verify: task prints rotated/failed counts and exits non-zero on failure.
  6. Deploy with `CLOAK_KEY=<new>` everywhere; keep the old key archived
     (offline) for 30 days, then destroy it.

  The task swaps `Treby.Vault` ciphers at runtime: rows are decrypted with
  the old key, then re-encrypted with the new key on update.
  """

  use Mix.Task

  alias Treby.Calendar.CalendarConnection
  alias Treby.Repo

  @impl Mix.Task
  def run(_args) do
    Mix.Task.run("app.start")

    old_key = decode_env!("OLD_CLOAK_KEY")
    new_key = decode_env!("CLOAK_KEY")

    if old_key == new_key do
      Mix.raise("OLD_CLOAK_KEY and CLOAK_KEY must differ")
    end

    put_vault_key(old_key)
    rows = Repo.all(CalendarConnection)

    {ok, failed} =
      Enum.reduce(rows, {0, []}, fn row, {ok_count, failures} ->
        case rotate_row(row, new_key) do
          :ok -> {ok_count + 1, failures}
          {:error, reason} -> {ok_count, [{row.id, reason} | failures]}
        end
      end)

    Mix.shell().info("Rotated #{ok} calendar connection(s).")

    if failed == [] do
      :ok
    else
      Enum.each(failed, fn {id, reason} ->
        Mix.shell().error("  failed #{id}: #{inspect(reason)}")
      end)

      exit({:shutdown, 1})
    end
  end

  defp rotate_row(%CalendarConnection{} = row, new_key) do
    # Fields were decrypted on load with the old key (vault holds it now).
    if is_nil(row.access_token) do
      {:error, :decrypt_failed}
    else
      put_vault_key(new_key)

      result =
        row
        |> Ecto.Changeset.change(%{
          access_token: row.access_token,
          refresh_token: row.refresh_token
        })
        |> Repo.update()

      # Restore the old key so the next row decrypts correctly.
      put_vault_key(current_old_key!())

      case result do
        {:ok, _} -> :ok
        {:error, changeset} -> {:error, changeset.errors}
      end
    end
  end

  defp current_old_key! do
    System.get_env("OLD_CLOAK_KEY") |> decode_key!("OLD_CLOAK_KEY")
  end

  defp put_vault_key(key_bytes) do
    :sys.replace_state(Treby.Vault, fn config ->
      Keyword.put(config, :ciphers,
        default: {Cloak.Ciphers.AES.GCM, tag: "AES.GCM.V1", key: key_bytes}
      )
    end)

    :ok
  end

  defp decode_env!(var) do
    System.get_env(var) |> decode_key!(var)
  end

  defp decode_key!(nil, var), do: Mix.raise("Missing environment variable #{var}")
  defp decode_key!("", var), do: Mix.raise("Missing environment variable #{var}")

  defp decode_key!(value, var) do
    case Base.decode64(value) do
      {:ok, bytes} -> bytes
      :error -> Mix.raise("#{var} is not valid base64")
    end
  end
end
