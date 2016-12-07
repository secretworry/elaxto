defmodule Elaxto.Schema do

  alias __MODULE__

  def traverse( schema, acc, pre, post) do
    {schema, acc} = pre.(schema, acc)
    do_traverse(schema, acc, pre, post)
  end

  defp do_traverse(%Schema.Type{fields: fields} = type, acc, pre, post) do
    {fields, acc} = do_traverse_fields(fields, acc, pre, post)
    post.(%{type | fields: fields}, acc)
  end

  defp do_traverse(%Schema.Field{type: type} = field, acc, pre, post) do
    {type, acc} = case type do
      atom when is_atom(atom) -> {field, acc}
      {:list, type} when is_atom(type) -> {field, acc}
      {composite_type, type} ->
        {schema, acc} = pre.(type, acc)
        {type, acc} = do_traverse(schema, acc, pre, post)
        {{composite_type, type}, acc}
    end
    post.(%{field | type: type}, acc)
  end

  defp do_traverse(nil, acc, _, _), do: acc

  defp do_traverse_fields(fields, acc, pre, post) do
    Enum.map_reduce(fields, acc, fn field, acc ->
      {schema, acc} = pre.(field, acc, pre, post)
      do_traverse(schema, acc, pre, post)
    end)
  end
end