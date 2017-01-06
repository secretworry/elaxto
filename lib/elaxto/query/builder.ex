defmodule Elaxto.Query.Builder do
  @moduledoc false

  @type t :: %__MODULE__{stack: [stack_item]}

  @type key :: atom | integer
  @type value :: any
  @type stack_item :: {:list, :call | :compound | nil, list} | {:map, list} | {:value, any} | {:pair, String.t | nil, value | nil} | {:call, Stringt.t, any} | {:escape, value}

  defstruct [stack: []]

  def build(ast, base_type \\ :map) do
    context = create_context() |> push_stack(base_type(base_type))
    {_, context} = Macro.traverse(ast, context, &pre/2, &post/2)
    %{stack: [value]} = context
    finalize_value(:map, value)
  end

  defp base_type(:map) do
    {:map, []}
  end

  defp base_type(:list) do
    {:list, nil, []}
  end

  defp create_context() do
    %__MODULE__{}
  end

  defp pre({:^, _, [expr]}, context) do
    context = context |> push_stack({:escape, expr})
    # no further traverse on the subtree
    {:nil, context}
  end

  defp pre({:%{}, _, _} = node, context) do
    context = context |> push_stack({:map, []})
    {node, context}
  end

  defp pre({query, _, _} = node, context) do
    context = context |> push_stack({:call, to_string(query), nil, nil})
    {node, context}
  end

  defp pre([{_, _}|_] = list, context) do
    context = context |> push_stack({:map, []})
    {list, context}
  end

  defp pre(list, context) when is_list(list) do
    context = context |> push_stack({:list, nil, []})
    {list, context}
  end

  defp pre({_, _} = node, context) do
    context = context |> push_stack({:pair, nil, nil})
    {node, context}
  end

  defp pre(value, context)do
    context = context |> push_stack({:value, value})
    {value, context}
  end

  defp post(node, context) do
    context = context |> pop_and_merge
    {node, context}
  end

  defp push_stack(%{stack: stack} = context, value) do
    %{context | stack: [value | stack]}
  end

  defp pop_and_merge(%{stack: stack} = context) do
    [current, parent | rest] = stack
    new_node = do_merge(current, parent)
    #IO.puts("do_merge(#{inspect current}, #{inspect parent}) = #{inspect new_node}")
    %{context | stack: [new_node|rest]}
  end

  defp call_value_type({_, _}), do: :pair
  defp call_value_type([{_, _}|_]), do: :map
  defp call_value_type(list) when is_list(list), do: :list

  defp call_value_type(_), do: :item

  defp do_merge(current, {:call, call, nil, nil}) do
    value = finalize_value(:call, current)
    type = call_value_type(value)
    case type do
      :item -> {:call, call, :item, value}
      :pair -> {:call, call, :map, [value]}
      :map  -> {:call, call, :map, value}
      :list -> {:call, call, :list, value}
    end

  end

  defp do_merge(current, {:call, call, :item, value}) do
    new_value = finalize_value(:call, current)
    type = call_value_type(value)
    case type do
      :item -> {:call, call, :list, [new_value, value]}
      :pair -> {:call, call, :list, [new_value, value]}
      :map  -> {:call, call, :list, new_value ++ [value]}
      :list -> {:call, call, :list, new_value ++ [value]}
    end

  end

  defp do_merge(current, {:call, call, :map, value}) do
    new_value = finalize_value(:call, current)
    type = call_value_type(new_value)
    case type do
      :map  -> {:call, call, :map, new_value ++ value}
      :pair -> {:call, call, :map, [new_value | value]}
      :item -> {:call, call, :list, [new_value | value]}
      :list -> {:call, call, :list, new_value ++ value}
    end
  end

  defp do_merge(current, {:call, call, :list, value}) do
    new_value = finalize_value(:call, current)
    type = call_value_type(new_value)
    case type do
      :map  -> {:call, call, :list, new_value ++ value}
      :pair -> {:call, call, :list, [new_value | value]}
      :item -> {:call, call, :list, [new_value | value]}
      :list -> {:call, call, :list, new_value ++ value}
    end
  end

  defp do_merge({:list, :call, list}, {:list, nil, []}) do
    # merge a list of calls into a list without any other type change the list into a map
    # i.e. [[bar(key: "value"), foo(key: "value")]] => %{"bar" => %{"key" => "value"}, "foo" => %{"key" => "value"}}

    map = list
    |> Enum.reduce(Map.new, fn
      {:%{}, [], [{key, {:%{}, [], values}}]}, map ->
        Map.update(map, key, values, &(values ++ &1))
    end)
    |> Enum.map(fn
      {key, values} ->
        quote do: {unquote(key), %{unquote_splicing(values)}}
    end)
    {:map, map}
  end

  defp do_merge(current, {:list, list_type, list}) do
    item_type = elem(current, 0)
    {:list, list_type(item_type, list_type), [ finalize_value(:list, current) | list]}
  end

  defp do_merge({:map, child_map}, {:map, map}) do
    {:map, child_map ++ map}
  end

  defp do_merge(current, {:map, map}) do
    {:map, [finalize_value(:map, current) | map]}
  end

  defp do_merge({:value, key}, {:pair, nil, nil}) do
    {:pair, to_string(key), nil}
  end

  defp do_merge(value, {:pair, key, nil}) when not is_nil(key) do
    {:pair, key, finalize_value(:pair, value)}
  end

  def list_type(child_type, nil), do: child_type
  def list_type(type, type), do: type
  def list_type(_, _), do: :compound

  defp finalize_value(_parent, {:list, _type, list}) do
    quote do
      unquote(list |> Enum.reverse)
    end
  end

  defp finalize_value(:call, {:map, map}) do
    map
  end

  defp finalize_value(_parent, {:map, map}) do
    quote do
      %{unquote_splicing(map |> Enum.reverse)}
    end
  end

  defp finalize_value(_parent, {:pair, key, nil}) do
    quote do
      {unquote(key), %{}}
    end
  end

  defp finalize_value(_parent, {:pair, key, value}) do
    quote do
      {unquote(key), unquote(value)}
    end
  end

  defp finalize_value(parent, {:call, key, type, value}) when parent in [:map, :call] do
    quote do
      {unquote(key), unquote(finalize_call_value(type, value))}
    end
  end

  defp finalize_value(_parent, {:call, key, type, value}) do
    quote do
      %{unquote({key, finalize_call_value(type, value)})}
    end
  end

  defp finalize_value(_parent, {:value, value}) when is_boolean(value) do
    value
  end

  defp finalize_value(_parent, {:value, value}) when is_atom(value) do
    to_string(value)
  end

  defp finalize_value(_parent, {:value, value}), do: value

  defp finalize_value(_parent, {:key, key}) do
    quote do
      {unquote(to_string(key)), %{}}
    end
  end

  defp finalize_value(_parent, {:escape, expr}) do
    expr
  end

  defp finalize_value(_parent, value), do: value

  defp finalize_call_value(nil, _value), do: quote(do: %{})

  defp finalize_call_value(:item, value), do: value

  defp finalize_call_value(:map, values) do
    quote do
      %{unquote_splicing(values |> Enum.reverse)}
    end
  end

  defp finalize_call_value(:list, value) do
    list_values = value
    |> Enum.reverse
    |> Enum.map(fn
      {key, value} -> quote do: %{unquote({key, value})}
      value -> value
    end)
    quote do
      [unquote_splicing(list_values)]
    end
  end
end