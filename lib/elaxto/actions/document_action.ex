defmodule Elaxto.DocumentAction do
  @moduledoc """
  Action to invoke ElasticSearch Document API
  """

  @type t :: %__MODULE__{
    id: String.t | integer | nil,
    index: atom,
    type: atom,
    document: Map.t,
    opts: Keyword.t
  }

  @enforce_keys ~w{index type document}a
  defstruct [:index, :type, :document, id: nil, opts: []]

end