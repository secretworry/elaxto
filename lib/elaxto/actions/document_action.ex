defmodule Elaxto.DocumentAction do
  @moduledoc """
  Action to invoke ElasticSearch Document API
  """

  @type t :: %__MODULE__{
    id: String.t | integer | nil,
    type: atom,
    document: Map.t,
    opts: Map.t
  }

  @enforce_keys ~w{type document}a
  defstruct [:type, :document, id: nil, opts: %{}]

  def new(type, id \\ nil, document) do
    %__MODULE__{type: type, id: id, document: document}
  end

end