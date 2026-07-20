defmodule Treby.Encrypted.Binary do
  @moduledoc false
  use Cloak.Ecto.Binary, vault: Treby.Vault
end
