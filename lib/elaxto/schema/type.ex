defmodule Elaxto.Schema.Type do

  alias __MODULE__


  @type t :: %__MODULE__{
    name: String.t,
    meta: Type.Meta.t,
    fields: %{atom => Elaxtor.Schema.Field.t}
  }

  @enforce_keys ~w{name}a
  defstruct name: nil, meta: nil, fields: %{}

  defmodule Meta do

    @type t :: %__MODULE__{
      all: boolean
    }
    defstruct all: false
  end
end