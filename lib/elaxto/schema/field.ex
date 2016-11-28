defmodule Elaxto.Schema.Field do

  @type type_t :: {:list, atom} | {:object, %{atom => t}} | {:nested, %{atom => t}} | atom
  @type resolver_t :: (any, any -> any) | nil

  @type t :: %__MODULE__{
    type: type_t,
    name: String.t,
    parameters: %{atom => any},
    resolver: resolver_t | nil
  }

  @enforce_keys ~w{type name}a
  defstruct type: nil, name: nil, parameters: %{}, resolver: nil

end