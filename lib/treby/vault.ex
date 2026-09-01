defmodule Treby.Vault do
  @moduledoc false
  use Cloak.Vault, otp_app: :treby

  @impl GenServer
  def init(config) do
    config =
      Keyword.put(config, :ciphers,
        default: {Cloak.Ciphers.AES.GCM, tag: "AES.GCM.V1", key: decode_env!("CLOAK_KEY")}
      )

    {:ok, config}
  end

  defp decode_env!(var) do
    env_value =
      case System.get_env(var) do
        nil -> nil
        "" -> nil
        v -> v
      end

    key =
      env_value ||
        Application.get_env(:treby, :cloak_key) ||
        raise "Missing encryption key: set the #{var} environment variable or configure :cloak_key"

    Base.decode64!(key)
  end
end
