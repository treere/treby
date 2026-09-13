defmodule Treby.AI.Tools.ExplainPage do
  @moduledoc "Read-only tool: describe the page the user is currently on."

  def name, do: "explain_page"

  def description,
    do: "Explain the page the user is currently viewing and how to accomplish a goal on it."

  def destructive?, do: false

  def schema do
    %{
      "type" => "object",
      "properties" => %{
        "question" => %{"type" => "string", "description" => "What the user wants to do"}
      }
    }
  end

  def run(args, ctx) do
    {:ok,
     %{
       "question" => args["question"],
       "page" => ctx[:page],
       "url" => ctx[:url],
       "params" => ctx[:params],
       "assigns" => ctx[:assigns_snapshot]
     }}
  end
end
