defmodule Elaxto.Query.Builder do
  @moduledoc false

  @type t :: %__MODULE__{stack: [stack_item]}

  @type key :: atom | integer
  @type value :: any
  @type stack_item :: {:list, :call | :compound | nil, list} | {:map, list} | {:value, any} | {:pair, String.t | nil, value | nil} | {:call, Stringt.t, any} | {:escape, value}

  defstruct [stack: []]

  def build(ast) do
    context = create_context() |> push_stack({:map, []})
    {_, context} = Macro.traverse(ast, context, &pre/2, &post/2)
    %{stack: [value]} = context
    finalize_value(:map, value)
  end

  defp create_context() do
    %__MODULE__{}
  end

  defp pre({:^, _, [expr]}, context) do
    context = context |> push_stack({:escape, expr})
    # no further traverse on the subtree, but will added a {:value, :nil} on the stack, we will handle it in the merge call
    {:nil, context}
  end

  defp pre({query, _, _} = node, context) do
    context = context |> push_stack({:call, to_string(query), nil})
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
    %{context | stack: [new_node|rest]}
  end

  defp do_merge(_ignore, {:escape, expr}) do
    {:escape, expr}
  end

  defp do_merge(current, {:call, call, nil}) do
    {:call, call, finalize_value(:call, current)}
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

  defp finalize_value(:map, {:call, key, value}) do
    quote do
      {unquote(key), unquote(value || (%{} |> Macro.escape))}
    end
  end

  defp finalize_value(_parent, {:call, key, value}) do
    quote do
      %{unquote({key, value || (%{} |> Macro.escape)})}
    end
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
end