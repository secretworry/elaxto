defmodule Elaxto.DocumentAction do
  @moduledoc """
  Action to invoke ElasticSearch Document API
  """

  @type error :: {String.t, Keyword.t}

  @type action :: :index | :delete

  @type t :: %__MODULE__{
    id: String.t | integer | nil,
    action: action,
    index: atom,
    type: atom,
    document: Map.t | nil,
    opts: Keyword.t,
    valid?: boolean,
    errors: [error],
  }

  @enforce_keys ~w{index type}a
  defstruct [:index, :type, document: nil, id: nil, action: :index, opts: [], valid?: true, errors: []]

end