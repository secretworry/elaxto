defmodule Elaxto.Query do

  defmacro query(body) do
    ast = Elaxto.Query.Builder.build(body)
    quote do
      %{"query" => unquote(ast)}
    end
  end
end