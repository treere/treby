defmodule Treby.AI.Tools.ProposeFormFill do
  @moduledoc """
  Read-only tool: propose values for the form currently in context.

  It never mutates state; it returns a proposal the UI shows as a diff.
  Values are applied only on per-item confirmation.
  """

  def name, do: "propose_form_fill"

  def description,
    do: "Propose corrected or pre-filled values for the form the user is editing."

  def destructive?, do: false

  def schema do
    %{
      "type" => "object",
      "properties" => %{
        "values" => %{
          "type" => "object",
          "description" => "Map of form field => proposed value",
          "additionalProperties" => %{"type" => "string"}
        }
      },
      "required" => ["values"]
    }
  end

  def run(args, ctx) do
    values = args["values"] || %{}
    schema = ctx[:form_schema]

    changes =
      values
      |> Enum.map(fn {field, value} -> %{"field" => field, "value" => value} end)

    {:ok, %{"form" => schema, "changes" => changes}}
  end
end
