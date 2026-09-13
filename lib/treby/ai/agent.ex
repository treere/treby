defmodule Treby.AI.Agent do
  @moduledoc """
  Single blocking agent with a hand-written ReqLLM tool loop.

  Read tools run immediately; any destructive tool stops the loop, is stored as
  a `:pending_confirm` run, and waits for the user's explicit confirmation.
  Responses are not streamed: one broadcast per completed message.
  """

  alias Treby.AI.{Context, Conversations, Tools}

  require Logger

  @doc """
  Handle one user message: persist it, run the model loop, and persist/publish
  the outcome. Returns `{:ok, :complete}` or `{:ok, :pending}` or `{:error, reason}`.
  """
  def chat(socket, text) when is_binary(text) do
    if String.trim(text) == "" do
      {:error, :empty}
    else
      ctx = Context.build(socket)

      conversation =
        Conversations.get_or_create_conversation(ctx.tenant_id, ctx.user_id, ctx.session_id)

      {:ok, _user_message} =
        Conversations.create_message(conversation, %{role: "user", content: text})

      messages = build_messages(conversation, ctx)
      run_loop(conversation, ctx, messages, 0)
    end
  end

  @doc "Execute a confirmed destructive run and log one audit event."
  def confirm_tool_run(run, ctx) do
    case Tools.get(run.tool) do
      nil ->
        {:error, "unknown tool"}

      tool ->
        case tool.run(run.args, ctx) do
          {:ok, result} ->
            {:ok, _} =
              Conversations.update_tool_run(run, %{status: "executed", result: %{ok: result}})

            audit(run, ctx)
            {:ok, result}

          {:error, reason} ->
            {:ok, _} =
              Conversations.update_tool_run(run, %{status: "failed", result: %{error: reason}})

            {:error, reason}
        end
    end
  end

  @doc "Mark a pending run as rejected; no mutation, no audit."
  def reject_tool_run(run) do
    Conversations.update_tool_run(run, %{status: "rejected"})
  end

  defp run_loop(conversation, ctx, messages, iteration) do
    if iteration > max_iterations() do
      {:error, :too_many_iterations}
    else
      case complete(messages, conversation) do
        {:ok, response} ->
          handle_response(response, conversation, ctx, messages, iteration)

        {:error, reason} ->
          Logger.warning("AI completion failed: #{inspect(reason)}")
          {:error, reason}
      end
    end
  end

  defp handle_response(response, conversation, ctx, messages, iteration) do
    case ReqLLM.Response.classify(response) do
      %{type: :final_answer, text: text} ->
        {:ok, _message} =
          Conversations.create_message(conversation, %{role: "assistant", content: text})

        {:ok, :complete}

      %{type: :tool_calls, tool_calls: calls, text: text} ->
        case Enum.filter(calls, &destructive?/1) do
          [] ->
            next = append_reads(messages, response, calls, ctx)
            run_loop(conversation, ctx, next, iteration + 1)

          destructive ->
            persist_pending(conversation, text, destructive)
            {:ok, :pending}
        end
    end
  end

  defp append_reads(messages, response, calls, ctx) do
    results =
      Enum.map(calls, fn call ->
        ReqLLM.Context.tool_result(call.id, call.name, read_result(call, ctx))
      end)

    case ReqLLM.Context.append_tool_exchange(messages, response, results) do
      {:ok, next} -> next
      {:error, _} -> messages
    end
  end

  defp read_result(call, ctx) do
    case Tools.get(call.name) do
      nil ->
        Jason.encode!(%{error: "unknown tool"})

      tool ->
        case tool.run(decode_args(call.arguments), ctx) do
          {:ok, result} -> Jason.encode!(%{ok: result})
          {:error, reason} -> Jason.encode!(%{error: Tools.format_errors(reason)})
        end
    end
  end

  defp persist_pending(conversation, text, calls) do
    content =
      case text do
        blank when blank in [nil, ""] -> "I need your confirmation before continuing."
        text -> text
      end

    {:ok, message} =
      Conversations.create_message(conversation, %{role: "assistant", content: content})

    Enum.each(calls, fn call ->
      {:ok, _run} =
        Conversations.create_tool_run(message, %{
          tool: call.name,
          args: decode_args(call.arguments),
          status: "pending_confirm"
        })
    end)
  end

  defp build_messages(conversation, ctx) do
    history =
      conversation
      |> Conversations.list_messages()
      |> Enum.map(fn message ->
        ReqLLM.Context.text(role(message.role), message.content || "")
      end)

    ReqLLM.Context.new([ReqLLM.Context.system(ctx.system_prompt) | history])
  end

  defp role("assistant"), do: :assistant
  defp role("system"), do: :system
  defp role(_), do: :user

  defp destructive?(call) do
    case Tools.get(call.name) do
      nil -> false
      tool -> tool.destructive?()
    end
  end

  defp decode_args(%{} = args), do: args

  defp decode_args(args) when is_binary(args) do
    case Jason.decode(args) do
      {:ok, decoded} when is_map(decoded) -> decoded
      _ -> %{}
    end
  end

  defp decode_args(_), do: %{}

  defp complete(messages, conversation) do
    ReqLLM.generate_text(
      model_spec(),
      messages,
      [tools: llm_tools()] ++ request_opts(conversation)
    )
  rescue
    error -> {:error, Exception.message(error)}
  end

  defp llm_tools do
    Enum.map(Tools.all(), fn tool ->
      ReqLLM.Tool.new!(
        name: tool.name(),
        description: tool.description(),
        parameter_schema: tool.schema(),
        callback: fn _args -> {:ok, nil} end
      )
    end)
  end

  defp audit(run, ctx) do
    Treby.Audit.log_event("ai.tool.executed", "ai_tool_run", run.id, %{
      tenant_id: run.tenant_id,
      actor_id: ctx[:user] && ctx[:user].id,
      metadata: %{
        via: "ai",
        prompt_excerpt: Conversations.prompt_excerpt(run),
        tool: run.tool,
        args: run.args
      }
    })
  end

  # When a custom base URL is configured the endpoint is treated as
  # OpenAI-compatible (mirrors the provider setup used elsewhere in the app).
  defp model_spec do
    ai = ai_config()

    case normalize_base_url(ai[:base_url]) do
      nil ->
        "#{ai[:provider] || "anthropic"}:#{ai[:model] || "claude-3-5-sonnet-20240620"}"

      base_url ->
        ReqLLM.model!(%{
          provider: :openai,
          id: ai[:model] || "deepseek-v4-flash",
          base_url: base_url
        })
    end
  end

  defp request_opts(conversation) do
    ai = ai_config()

    opts =
      case ai[:api_key] || System.get_env("AI_API_KEY") do
        key when is_binary(key) and key != "" -> [api_key: key]
        _ -> []
      end

    case normalize_base_url(ai[:base_url]) do
      nil -> opts
      _ -> Keyword.put(opts, :req_http_options, headers: provider_headers(conversation))
    end
  end

  defp provider_headers(conversation) do
    [
      {"x-opencode-session", "treby-#{conversation.id}"},
      {"user-agent", "treby-ai/1.0"}
    ]
  end

  defp normalize_base_url(nil), do: nil
  defp normalize_base_url(""), do: nil

  defp normalize_base_url(url) when is_binary(url) do
    url =
      url
      |> String.trim_trailing("/")
      |> String.replace_suffix("/chat/completions", "")
      |> String.replace_suffix("/responses", "")

    if url == "", do: nil, else: url
  end

  defp ai_config, do: Application.get_env(:treby, :ai, [])

  defp max_iterations do
    ai_config()[:max_iterations] || 6
  end
end
