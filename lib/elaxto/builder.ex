defmodule Elaxto.Builder do
  @moduledoc false

  defstruct type_definitions: %{}, types: %{}, field_definitions: %{}, fields: %{}

  defmacro __using__(_opts) do
    quote do
      use Elaxto.Builder.Notation
      @before_compile Elaxto.Builder
    end
  end

  defmacro __before_compile__(env) do
    definition = build_definition(env)
    [
      definition.type_definitions,
      quote do
        def __elaxto_type__(_), do: nil
      end,
      definition.field_definitions,
      quote do
        def __elaxto_field__(_), do: nil
      end
    ]
  end

  defp build_definition(env) do
    types = Elaxto.Builder.Notation.get_types(env.module)
    %__MODULE__{}
    |> update_types(types)
    |> update_fields(types)
    |> update_type_definitions
    |> update_field_definitions
  end

  defp update_types(definition, types) do
    types = Enum.map(types, fn {type_name, type_attrs} ->
      fields_ast = quote_define_fields(type_attrs[:fields] || [])
      meta_ast = quote_type_meta(type_attrs)
      {type_name, quote do
        %Elaxto.Schema.Type{
          name: unquote(type_name),
          meta: unquote(meta_ast),
          fields: unquote(fields_ast)
        }
      end}
    end) |> Enum.into(%{})
    %{definition | types: types}
  end

  defp update_fields(definition, types) do
    fields = Enum.reduce(types, Map.new, fn {_, type_attrs}, map ->
      quote_field_fields(type_attrs[:fields] || [], map)
    end)
    %{definition | fields: fields}
  end

  defp update_type_definitions(%{types: types} = definition) do
    type_definitions = Enum.map(types, fn {type_name, type_ast} ->
      quote do
        def __elaxto_type__(unquote(type_name)), do: unquote(type_ast)
      end
    end)
    %{definition | type_definitions: type_definitions}
  end

  defp update_field_definitions(%{fields: fields} = definition) do
    field_definitions = Enum.map(fields, fn {field_name, field_ast} ->
      quote do
        def __elaxto_field__(unquote(field_name)), do: unquote(field_ast)
      end
    end)
    %{definition | field_definitions: field_definitions}
  end

  defp quote_type_meta(attrs) do
    %Elaxto.Schema.Type.Meta{all: !!Keyword.get(attrs, :all)} |> Macro.escape
  end

  defp quote_define_fields(fields) when is_list(fields) do
    fields_ast = for {field_name, attrs} <- fields do
      field_ast = quote do: %Elaxto.Schema.Field{unquote_splicing(attrs)}
      {field_name, field_ast}
    end
    quote do %{unquote_splicing(fields_ast)} end
  end

  defp quote_field_fields(fields, acc) when is_list(fields) do
    Enum.reduce(fields, acc, fn {field_name, attrs}, acc ->
      case Keyword.get(attrs, :type) do
        :field ->
          field_ast = quote do: %Elaxto.Schema.Field{unquote_splicing(attrs)}
          Map.put(acc, field_name, field_ast)
        _ ->
          acc
      end
    end)
  end
end