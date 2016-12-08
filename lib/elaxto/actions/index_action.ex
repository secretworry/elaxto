defmodule Elaxto.IndexAction do
  @docmodule """
  Action to invoke Indeces API
  """

  @type t :: %__MODULE__{
    name: atom,
    settings: Map.t,
    alias: Map.t,
    mappings: Map.t,
    opts: Keyword.t
  }

  @type diff_result_t :: Map.t | nil

  @enforce_keys ~w{name mappings}a
  defstruct [:name, :mappings, settings: nil, alias: nil, opts: []]
end