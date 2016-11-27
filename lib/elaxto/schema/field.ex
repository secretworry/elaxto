defmodule Elaxto.Schema.Field do

  @type type_t :: :field | :property
  @type field_type_t :: {:list, atom} | {:object, %{atom => t}} | {:nested, %{atom => t}} | atom
  @type resolver_t :: (any, any -> any) | nil

  @type t :: %__MODULE__{
    type: type_t,
    name: String.t,
    field_type: field_type_t,
    parameters: %{atom => any},
    resolver: resolver_t | nil
  }

  @enforce_keys ~w{type name field_type}a
  defstruct type: nil, name: nil, field_type: nil, parameters: %{}, resolver: nil

end