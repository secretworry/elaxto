defmodule Elaxto.Schema.Field do

  @type type_t :: :field | :property
  @type field_type_t :: atom | {:list, atom} | {:object, [t]} | :nested

  @type t :: %__MODULE__{
    type: type_t,
    field_type: field_type_t,
    parameters: %{atom => any}
  }

  @enforce_keys ~w{type field_type}
  defstruct type: nil, field_type: nil, parameters: %{}

end