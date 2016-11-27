defmodule Elaxto.DocumentAction do

  @type method :: :get | :put | :delete | :post

  @type opts :: %{String.t => String.t}

  @type t :: %__MODULE__{
    type: String.t,
    opts: opts,
    id: String.t,
    method: method,
  }

  @enforce_keys ~w{type method}
  defstruct [
    type: nil,
    opts: %{},
    id: nil,
    method: :get
  ]
end