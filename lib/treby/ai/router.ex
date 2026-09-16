defmodule Treby.AI.Router do
  @moduledoc "LLM intent classifier that selects a specialized agent domain."

  alias Treby.AI.{LLM, Profiles}

  @domains Profiles.domains()

  @doc """
  Classify the user's intent into a domain.

  Sticky: returns `last_domain` when the model is uncertain or fails, so the
  previous agent keeps handling the conversation.
  """
  def classify(history, text, last_domain \\ nil) do
    messages = [
      ReqLLM.Context.system(system_prompt()),
      ReqLLM.Context.text(:user, history_text(history, text))
    ]

    case LLM.generate(messages) do
      {:ok, raw} -> parse_classification(raw, last_domain)
      {:error, _} -> last_domain || :recruiter
    end
  end

  @doc """
  Map raw model text to a domain atom, falling back to `last_domain`
  (then `:recruiter`) when the text is not a single known domain word.
  Public so the classifier logic is unit-testable without an LLM call.
  """
  def parse_classification(raw, last_domain \\ nil) do
    parse(raw, last_domain)
  end

  defp system_prompt do
    domains = Enum.join(@domains, ", ")

    "Classify the user's request into exactly one of these domains: #{domains}. Reply with only the single domain word, lowercase, nothing else."
  end

  defp history_text(history, text) do
    prior =
      history
      |> Enum.take(-6)
      |> Enum.map_join("\n", fn {role, content} -> "#{role}: #{content}" end)

    "#{prior}\nuser: #{text}"
  end

  defp parse(raw, last_domain) do
    word = raw |> String.trim() |> String.downcase() |> String.split() |> List.first()
    domain_strings = Enum.map(@domains, &to_string/1)

    if is_binary(word) and word in domain_strings do
      String.to_existing_atom(word)
    else
      last_domain || :recruiter
    end
  end
end
