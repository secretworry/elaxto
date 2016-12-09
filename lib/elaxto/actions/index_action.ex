defmodule Elaxto.IndexAction do
  @docmodule """
  Action to invoke Indeces API
  """

  @type error :: {String.t, Keyword.t}

  @type t :: %__MODULE__{
    name: atom,
    settings: Map.t,
    alias: Map.t,
    mappings: Map.t,
    opts: Keyword.t,
    valid?: boolean,
    errors: [error]
  }

  @type diff_result_t :: Map.t | nil

  @enforce_keys ~w{name mappings}a
  defstruct [:name, :mappings, settings: nil, alias: nil, opts: [], valid?: true, errors: []]
end