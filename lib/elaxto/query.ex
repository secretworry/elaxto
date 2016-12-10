defmodule Elaxto.Query do

  @type t :: Map.t

  defmacro query(body) do
    ast = Elaxto.Query.Builder.build(body)
    quote do
      %{"query" => unquote(ast)}
    end
  end

  def merge(query1, query2) when is_map(query1) and is_map(query2)do
    do_merge(query1, query2)
  end

  defp do_merge(nil, query2), do: query2
  defp do_merge(query1, nil), do: query1

  defp do_merge(query1, query2) when is_map(query1) and is_map(query2) do
    Map.merge(query1, query2, fn
      _k, v1, v2 ->
        do_merge(v1, v2)
    end)
  end

  defp do_merge(query1, query2) when is_list(query1) and is_list(query2) do
    query1 ++ query2
  end

  defp do_merge(query1, query2) do
    [query1, query2]
  end
end