defmodule Treby.AI.Router do
  @moduledoc """
  LLM intent classifier that selects a specialized agent domain.

  Returns one of `recruiter`, `analytics`, `comms`, `admin`, `:out_of_domain`
  or `:malicious`. The two refusal atoms mean the request should not run the
  agent loop; the caller decides how to refuse.
  """

  alias Treby.AI.{LLM, Profiles}

  @domains Profiles.domains()
  @refusal_domains [:out_of_domain, :malicious]
  @classify_domains @domains ++ @refusal_domains
  @domain_words Map.new(@classify_domains, fn domain -> {to_string(domain), domain} end)

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
    domains = Enum.join(@classify_domains, ", ")

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

    case Map.fetch(@domain_words, word) do
      {:ok, domain} -> domain
      :error -> last_domain || :recruiter
    end
  end
end
