defmodule TrebyWeb.HealthController do
  use TrebyWeb, :controller

  def health(conn, _params) do
    conn
    |> put_resp_header("cache-control", "no-store, no-cache, must-revalidate")
    |> put_resp_header("pragma", "no-cache")
    |> json(%{status: "ok"})
  end

  def ready(conn, _params) do
    checks = check_all()

    status = if checks.database == "ok", do: "ok", else: "error"
    http_status = if status == "ok", do: 200, else: 503

    conn
    |> put_resp_header("cache-control", "no-store, no-cache, must-revalidate")
    |> put_resp_header("pragma", "no-cache")
    |> put_status(http_status)
    |> json(%{status: status, checks: checks})
  end

  defp check_all do
    db_task = Task.async(&check_database/0)
    storage_task = Task.async(&check_storage/0)

    database =
      case Task.yield(db_task, 2000) || Task.shutdown(db_task, :brutal_kill) do
        {:ok, result} -> result
        nil -> "error"
      end

    storage =
      case Task.yield(storage_task, 2000) || Task.shutdown(storage_task, :brutal_kill) do
        {:ok, result} -> result
        nil -> "error"
      end

    %{database: database, storage: storage}
  end

  defp check_database do
    case Application.get_env(:treby, :health_db_status) do
      :ok -> "ok"
      :error -> "error"
      _ -> do_db_check()
    end
  end

  defp do_db_check do
    case Treby.Repo.query("SELECT 1", [], timeout: 2000) do
      {:ok, _} -> "ok"
      {:error, _} -> "error"
    end
  rescue
    _ -> "error"
  catch
    _, _ -> "error"
  end

  defp check_storage do
    case Application.get_env(:treby, :health_storage_status) do
      :ok ->
        "ok"

      :error ->
        "error"

      :skipped ->
        "skipped"

      _ ->
        if System.get_env("HEALTH_CHECK_S3") in ["true", "1"] do
          do_storage_check()
        else
          "skipped"
        end
    end
  end

  defp do_storage_check do
    case ExAws.S3.list_buckets() |> ExAws.request(http_opts: [receive_timeout: 2000]) do
      {:ok, _} -> "ok"
      {:error, _} -> "error"
    end
  rescue
    _ -> "error"
  catch
    _, _ -> "error"
  end
end
