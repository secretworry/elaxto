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


  def queriable_to_uri(_config, nil, opts) do
    do_queriable_to_uri("/", opts)
  end

  def queriable_to_uri(config, index, opts) when is_atom(index) do
    do_queriable_to_uri("/#{prefix_index(config, index)}", opts)
  end

  def queriable_to_uri(config, {index, type}, opts) when is_binary(type) or is_atom(type) do
    do_queriable_to_uri("/#{prefix_index(config, index)}/#{type}", opts)
  end

  def queriable_to_uri(config, {index, types}, opts) when is_list(types) do
    do_queriable_to_uri("/#{prefix_index(config, index)}/#{types |> Enum.join(",")}", opts)
  end

  def queriable_to_uri(config, {index, type, id}, opts) do
    do_queriable_to_uri(["", prefix_index(config, index), type, id] |> Enum.join("/"), opts)
  end

  def queriable_to_uri(_config, path, opts) when is_binary(path) do
    path = case path do
      "/" <> _ -> path
      path -> "/" <> path
    end
    do_queriable_to_uri(path, opts)
  end

  defp do_queriable_to_uri(path, opts) do
    query = opts |> URI.encode_query
    URI.parse("#{path}?#{query}")
  end

  def prefix_index(%{prefix: prefix}, index) do
    prefix_non_special(prefix, index)
  end
  def prefix_index(_, index), do: index

  defp prefix_non_special(prefix, index) do
    case index |> to_string |> String.to_char_list do
      '_' ++ _ -> index
      _ -> "#{prefix}#{index}"
    end
  end

end