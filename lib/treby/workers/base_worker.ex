defmodule Treby.Workers.BaseWorker do
  @moduledoc """
  Shared bits for Oban workers: string/atom arg fallback and a
  per-worker backoff table. Retry policy (queue, attempts, table
  values) stays in each worker, copied verbatim.
  """

  defmacro __using__(_opts) do
    quote do
      import Treby.Workers.BaseWorker, only: [arg: 2]

      @impl Oban.Worker
      def backoff(%Oban.Job{attempt: attempt}) do
        Map.get(@backoff_by_attempt, attempt, @backoff_default)
      end
    end
  end

  @doc """
  Reads a job arg by atom key, accepting string or atom map keys.
  """
  def arg(args, key) when is_atom(key) do
    Map.get(args, Atom.to_string(key)) || Map.get(args, key)
  end
end
