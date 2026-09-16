defmodule Treby.AI.LLM do
  @moduledoc "Shared ReqLLM config + non-streaming text generation for routing/classify."

  alias ReqLLM

  def model_spec do
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

  def request_opts do
    ai = ai_config()

    case ai[:api_key] || System.get_env("AI_API_KEY") do
      key when is_binary(key) and key != "" -> [api_key: key]
      _ -> []
    end
  end

  @doc "Generate text (no tools) and return the assistant text."
  def generate(messages, opts \\ []) do
    case ReqLLM.stream_text(model_spec(), messages, opts ++ request_opts()) do
      {:ok, stream} ->
        {:ok, response} = ReqLLM.StreamResponse.process_stream(stream)
        {:ok, final_text(response)}

      {:error, reason} ->
        {:error, reason}
    end
  rescue
    error -> {:error, Exception.message(error)}
  end

  defp final_text(response) do
    case ReqLLM.Response.classify(response) do
      %{type: :final_answer, text: text} -> text
      _ -> ""
    end
  end

  defp ai_config, do: Application.get_env(:treby, :ai, [])

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
end
