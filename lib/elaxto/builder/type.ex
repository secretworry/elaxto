defmodule Elaxto.Builder.Type do

  alias Elaxto.Schema

  defmacro type(name, opts \\[], [do: block]) do
    opts = Macro.expand(opts, __CALLER__)
    define_type(name, opts, block)
  end

  defp define_type(name, opts, block) do
    meta = build_meta(opts) |> Macro.escape
    quote do
      Module.register_attribute(__MODULE__, :fields, accumulate: false, persist: false)
      @fields []
      unquote(block)
      @elaxto_type %Elaxto.Schema.Type{name: unquote(name), meta: unquote(meta), fields: Module.get_attribute(__MODULE__, :fields)}

      def __elaxto__(:type), do: @elaxto_type
    end
  end

  defp build_meta(opts) do
    %Schema.Type.Meta{all: !!Keyword.get(opts, :all)}
  end
end