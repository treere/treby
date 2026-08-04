defmodule Treby.CsvImport do
  import Ecto.Query, warn: false
  require Logger
  alias Treby.Repo
  alias Treby.CsvImport.ImportLog
  alias Treby.Candidates
  alias Treby.Candidates.Candidate
  alias Treby.Pipeline.Application

  NimbleCSV.define(CsvParser, separator: ",", escape: "\"")

  def parse_csv(csv_binary) do
    lines =
      csv_binary
      |> CsvParser.parse_string(skip_headers: false)
      |> Enum.map(fn row -> Enum.map(row, &String.trim/1) end)

    case lines do
      [headers | rows] ->
        rows =
          Enum.map(rows, fn row ->
            headers
            |> Enum.zip(row)
            |> Map.new()
          end)

        {:ok, %{rows: rows, headers: headers}}

      [] ->
        {:ok, %{rows: [], headers: []}}
    end
  rescue
    e -> {:error, "CSV parsing failed: #{Exception.message(e)}"}
  end

  def auto_detect_mapping(headers) do
    field_map = %{
      "name" => "name",
      "full_name" => "name",
      "candidate_name" => "name",
      "email" => "email",
      "email_address" => "email",
      "e-mail" => "email",
      "phone" => "phone",
      "phone_number" => "phone",
      "mobile" => "phone",
      "linkedin" => "linkedin_url",
      "linkedin_url" => "linkedin_url",
      "linkedin_profile" => "linkedin_url"
    }

    mapping =
      Enum.reduce(headers, %{}, fn header, acc ->
        normalized = header |> String.trim() |> String.downcase()

        case Map.get(field_map, normalized) do
          nil ->
            # Try substring matching
            matching_field =
              Enum.find_value(field_map, fn {key, field} ->
                if String.contains?(normalized, key), do: field
              end)

            if matching_field do
              Map.put(acc, header, matching_field)
            else
              acc
            end

          field ->
            Map.put(acc, header, field)
        end
      end)

    {:ok, mapping}
  end

  def validate_row(row, mapping) do
    errors = []

    # Check email is present
    email_value = get_mapped_value(row, mapping, "email")

    errors =
      if email_value in [nil, ""] do
        ["Email is required" | errors]
      else
        if email_value =~ ~r/@/ do
          errors
        else
          ["Invalid email format: #{email_value}" | errors]
        end
      end

    # Check name is present
    name_value = get_mapped_value(row, mapping, "name")

    errors =
      if name_value in [nil, ""] do
        ["Name is required" | errors]
      else
        errors
      end

    if errors == [], do: :ok, else: {:error, errors}
  end

  def preview_import(rows, mapping, tenant_id) do
    preview =
      rows
      |> Enum.take(10)
      |> Enum.map(fn row ->
        candidate_attrs = build_candidate_attrs(row, mapping)

        email = Map.get(candidate_attrs, "email", "")

        existing_candidate =
          if email != "" do
            normalized = String.downcase(String.trim(email))

            Candidate
            |> where(
              [c],
              c.tenant_id == ^tenant_id and c.email == ^normalized and is_nil(c.merged_into_id)
            )
            |> Repo.one()
          end

        validation = validate_row(row, mapping)

        %{
          row: row,
          candidate_attrs: candidate_attrs,
          is_duplicate: existing_candidate != nil,
          existing_candidate_id: if(existing_candidate, do: existing_candidate.id),
          validation: validation
        }
      end)

    {:ok, preview}
  end

  def execute_import(rows, mapping, tenant_id, opts \\ []) do
    job_id = opts[:job_id]
    pipeline_stage_id = opts[:pipeline_stage_id]
    source = opts[:source]

    results =
      rows
      |> Enum.reduce(%{imported: 0, skipped: 0, errors: []}, fn row, acc ->
        candidate_attrs = build_candidate_attrs(row, mapping)
        validation = validate_row(row, mapping)

        case validation do
          {:error, errors} ->
            %{acc | errors: acc.errors ++ [%{row: row, errors: errors}]}

          :ok ->
            case Candidates.find_or_create_candidate(tenant_id, candidate_attrs) do
              {:ok, candidate} ->
                if job_id && pipeline_stage_id do
                  # Check for duplicate application
                  existing_app =
                    Repo.get_by(Application,
                      candidate_id: candidate.id,
                      job_id: job_id
                    )

                  if existing_app do
                    %{acc | skipped: acc.skipped + 1}
                  else
                    application_attrs = %{
                      "candidate_id" => candidate.id,
                      "job_id" => job_id,
                      "pipeline_stage_id" => pipeline_stage_id,
                      "applied_at" => DateTime.utc_now(),
                      "tenant_id" => tenant_id,
                      "source" => source,
                      "anagrafica" =>
                        Map.take(candidate_attrs, [
                          "name",
                          "email",
                          "phone",
                          "linkedin_url"
                        ])
                    }

                    case Treby.Pipeline.create_application(application_attrs) do
                      {:ok, application} ->
                        try do
                          Treby.Notifications.notify_team_new_application(application)
                        rescue
                          e ->
                            require Logger

                            Logger.warning(
                              "Failed to send team notification for imported application: #{Exception.message(e)}"
                            )
                        end

                        %{acc | imported: acc.imported + 1}

                      {:error, _changeset} ->
                        %{
                          acc
                          | errors:
                              acc.errors ++
                                [%{row: row, errors: ["Failed to create application"]}]
                        }
                    end
                  end
                else
                  %{acc | imported: acc.imported + 1}
                end

              {:error, _changeset} ->
                %{
                  acc
                  | errors: acc.errors ++ [%{row: row, errors: ["Failed to create candidate"]}]
                }
            end
        end
      end)

    {:ok, results}
  end

  def log_import(file_name, tenant_id, results) do
    %ImportLog{}
    |> ImportLog.changeset(%{
      file_name: file_name,
      imported_count: results.imported,
      skipped_count: results.skipped,
      error_count: length(results.errors),
      tenant_id: tenant_id
    })
    |> Repo.insert()
  end

  defp build_candidate_attrs(row, mapping) do
    %{
      "name" => get_mapped_value(row, mapping, "name") || "",
      "email" => get_mapped_value(row, mapping, "email") || "",
      "phone" => get_mapped_value(row, mapping, "phone"),
      "linkedin_url" => get_mapped_value(row, mapping, "linkedin_url")
    }
    |> Enum.reject(fn {_k, v} -> v in [nil, ""] end)
    |> Map.new()
  end

  defp get_mapped_value(row, mapping, target_field) do
    mapping
    |> Enum.find(fn {_csv_header, field} -> field == target_field end)
    |> case do
      nil -> nil
      {csv_header, _field} -> Map.get(row, csv_header)
    end
  end
end
