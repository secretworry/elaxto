defmodule Elaxto.SearchAction do

  @moduledoc """
  Action to invoke ElasticSearch Document API
  """

  @type t :: %__MODULE__{
    index: atom,
    types: [atom],
    query: Map.t
  }

  @enforce_keys ~w{index types query}a
  defstruct [:index, :types, :query]
end