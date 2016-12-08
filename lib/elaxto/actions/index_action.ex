defmodule Elaxto.IndexAction do
  @docmodule """
  Action to invoke Indeces API
  """

  @type t :: %__MODULE__{
    name: atom,
    settings: Map.t,
    mappings: Map.t,
    opts: Map.t
  }

  @type diff_result_t :: {String.t, Map.t} | nil

  @enforce_keys ~w{name mappings}a
  defstruct [:name, :mappings, settings: %{}, opts: %{}]

  def new(name, mappings, settings \\ %{}) do
    %__MODULE__{name: name, mappings: mappings, settings: settings}
  end

  @spec diff(t, t) :: diff_result_t
  def diff(%__MODULE__{name: name} = new_action, %__MODULE__{name: name} = old_action) do
  end

  def diff(new_action, old_action) do
    raise ArgumentError, "Incompatitable action"
  end
end