defmodule Elaxto.DocumentAction do

  @type method :: :get | :put | :delete | :post

  @type opts :: %{String.t => String.t}

  @type t :: %__MODULE__{
    type: String.t,
    opts: opts,
    method: method,
    body: map
  }

  @enforce_keys ~w{type method}a
  defstruct [
    type: nil,
    opts: %{},
    method: :get,
    body: %{}
  ]

  defmodule IndexBuilder do

    defstruct type: nil, data: nil, action: nil, stack: [], parent: nil

    def build(type, data, opts) do
      action = %Elaxto.DocumentAction{type: type.name |> to_string, method: :put, opts: opts, body: %{}}
      context = %__MODULE__{parent: type, data: data, action: action}

      Elaxto.Schema.traverse(type, context, &pre_traverse/2, &post_traverse/2)
    end

    defp pre_traverse(%Elaxto.Schema.Type{} = type, %{data: nil} = acc) do
      {nil, acc}
    end

    defp pre_traverse(%Elaxto.Schema.Type{} = type, %{data: data} = acc) do
      {type, %{acc| parent: type}}
    end

    defp pre_traverse(%Elaxto.Schema.Field{} = field, %{data: data}) do
    end

    defp post_traverse(%Elaxto.Schema.Type{}, acc) do
    end

    defp post_traverse(%Elaxto.Schema.Field{}, acc) do
    end

    defp push_stack(context, attrs) do
      %{context | stack: [attrs | context.stack]}
    end

    def update_current(context, updater) do
      [current | tail] = context.stack
      current = updater.(current)
      %{context | stack: [current | tail]}
    end

    defp pop_stack(context) do
      [head | tail] = context.stack
      {head, %{context | stack: tail}}
    end

    defp resolve_field(field = %{field_type: field_type, name: name, resolver: resolver}, %{data: data} = context) do
      value = apply_resolver(field, context)
      cast(field_type, value)
    end

    defp apply_resolver(field, %{data: data}) do

    end
  end
end