defmodule Treby.AI.Control do
  @moduledoc """
  Outbound controller for the AI assistant.

  Runs once after the agent produces its final answer. It reviews the reply
  and returns a verdict plus (optionally) a cleaned reply:

  - `:pass` — appropriate and in-domain; keep (optionally re-formatted).
  - `:block` — inappropriate, off-topic, unsafe, or leaking data; refuse.
  - `:sanitize` — mostly fine but contains sensitive data; use the cleaned reply.

  This is best-effort. The real security boundary remains tenant-scoped queries
  plus human confirmation on destructive tools. On any LLM error or unparseable
  output it fails open to `:pass` and logs, so a broken reviewer never blocks a
  legitimate answer.
  """

  alias ReqLLM
  alias Treby.AI.LLM

  @doc "Review `text`. Returns `{:ok, verdict, reply}`."
  def evaluate(text, ctx, opts \\ [])

  def evaluate(text, _ctx, _opts) when not is_binary(text) or text == "",
    do: {:ok, :pass, text}

  def evaluate(text, _ctx, opts) do
    generate = Keyword.get(opts, :generate, &LLM.generate/1)

    messages = [
      ReqLLM.Context.system(system_prompt()),
      ReqLLM.Context.text(:user, "Reply to review:\n\n#{text}")
    ]

    case generate.(messages) do
      {:ok, raw} -> parse_verdict(raw, text)
      {:error, _} -> {:ok, :pass, text}
    end
  rescue
    _ -> {:ok, :pass, text}
  end

  @doc "Parse a model JSON verdict. Public so the logic is unit-testable without an LLM."
  def parse_verdict(raw, original) when is_binary(raw) do
    case Jason.decode(raw) do
      {:ok, %{"verdict" => verdict} = map} when verdict in ~w(pass block sanitize) ->
        atom = String.to_existing_atom(verdict)
        reply = Map.get(map, "reply", original)
        {:ok, atom, reply}

      _ ->
        {:ok, :pass, original}
    end
  end

  def parse_verdict(_, original), do: {:ok, :pass, original}

  @doc "Canned refusal used when the controller blocks a reply."
  def blocked_reply, do: "I can't respond to that request."

  defp system_prompt do
    """
    You are a safety reviewer for an internal hiring assistant. Given the assistant's reply, decide a verdict.

    - pass: the reply is appropriate, in-domain, well formatted, and contains no other tenant's data, secrets, or out-of-scope PII. You may re-format markdown.
    - block: the reply is inappropriate, off-topic, unsafe, or leaks data. Set "reply" to "".
    - sanitize: the reply is mostly fine but contains sensitive data (another tenant's data, secrets, or PII outside scope). Put the cleaned reply in "reply".

    Return ONLY a JSON object: {"verdict": "pass|block|sanitize", "reply": "<cleaned text or empty>", "reason": "<short>"}.
    Do not change the factual meaning of an in-scope answer.
    """
  end
end
