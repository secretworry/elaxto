defmodule Elaxto.RequestBuilder do
  @moduledoc false

  alias Elaxto.{DocumentAction, IndexAction}

  def to_queriable(%DocumentAction{index: index, type: type, id: id}) do
    {index, type, id}
  end

  def to_queriable(%IndexAction{ name: name}) do
    name
  end

  def to_query(%DocumentAction{document: document}) do
    document
  end

  def to_query(%IndexAction{settings: settings, alias: alias, mappings: mappings}) do
    body = %{"mappings" => mappings}
    body = case alias do
      nil -> body
      alias -> body |> Map.put("alias", alias)
    end
    body = case settings do
      nil -> body
      settings -> body |> Map.put("settings", settings)
    end
    body
  end


  def queriable_to_uri(nil, opts) do
    do_queriable_to_uri("/", opts)
  end

  def queriable_to_uri(index, opts) when is_binary(index) or is_atom(index) do
    do_queriable_to_uri("/#{index}", opts)
  end

  def queriable_to_uri({index, type}, opts) when is_binary(type) or is_atom(type) do
    do_queriable_to_uri("/#{index}/#{type}", opts)
  end

  def queriable_to_uri({index, types}, opts) when is_list(types) do
    do_queriable_to_uri("/#{index}/#{types |> Enum.join(",")}", opts)
  end

  def queriable_to_uri({index, type, id}, opts) do
    do_queriable_to_uri(["", index, type, id] |> Enum.join("/"), opts)
  end

  defp do_queriable_to_uri(path, opts) do
    query = opts |> URI.encode_query
    URI.parse("#{path}?#{query}")
  end
end