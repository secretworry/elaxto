defmodule Elaxto.Builder.Notation do

  alias Elaxto.Builder.Scope

  @type_attributes :elaxto_builder_types

  defmacro __using__(_opts) do
    Module.register_attribute(__CALLER__.module, @type_attributes, accumulate: false, persist: false)
    quote do
      import Elaxto.Builder.Notation
    end
  end

  defmacro type(identifier, attrs \\ [], [do: block]) do
    __CALLER__
    |> record_type(identifier, attrs, block)
  end

  defmacro field(identifier, type) do
    __CALLER__
    |> record_field(identifier, type, [], nil)
  end

  defmacro field(identifier, type, [do: block]) do
    __CALLER__
    |> record_field(identifier, type, [], block)
  end

  defmacro field(identifier, type, attrs) when is_list(attrs) do
    __CALLER__
    |> record_field(identifier, type, attrs, nil)
  end

  defmacro field(identifier, type, attrs, [do: block]) do
    __CALLER__
    |> record_field(identifier, type, attrs, block)
  end

  defmacro resolver(resolver) do
    Scope.put_attribute(__CALLER__.module, :resolver, resolver)
  end

  defmacro list_of(type) do
    {:list, type}
  end

  defp record_type(env, identifier, attrs, block) do
    scope(env, :type, identifier, attrs, block)
  end

  defp record_field(env, identifier, type, attrs, block) do

    attrs = []
    |> Keyword.put(:type, type)
    |> Keyword.put(:parameters, attrs |> Enum.into(%{}) |> Macro.escape)

    scope(env, :field, identifier, attrs, block)
  end

  def scope(env, kind, identifier, attrs, block) do
    open_scope(kind, env, attrs)
    block |> expand(env)
    close_scope(kind, env, identifier)
  end

  defp expand(ast, env) do
    Macro.prewalk(ast, fn
      {_, _, _} = node -> Macro.expand(node, env)
      node -> node
    end)
  end

  defp open_scope(kind, env, attrs) do
    Scope.open(kind, env.module, attrs)
  end

  defp close_scope(:type, env, identifier) do
    close_scope_and_define_type(env, identifier)
  end

  defp close_scope(:field, env, identifier) do
    close_scope_and_accumulate_field(env, identifier)
  end

  defp close_scope_with_name(mod, identifier, opts \\ []) do
    Scope.close(mod).attrs
    |> add_name(identifier, opts)
  end

  def add_name(attrs, identifier, opts \\ []) do
    update_in(attrs, [:name], fn
      value -> default_name(attrs, identifier, value, opts)
    end)
  end

  defp default_name(attrs, identifier, nil, opts) do
    case opts[:name_attr] do
      nil -> identifier
      attr_name -> Keyword.get(attrs, attr_name, identifier)
    end
  end

  defp default_name(_, _, name, _), do: name

  defp close_scope_and_accumulate_field(env, identifier) do
    Scope.put_attribute(env.module, :fields, {identifier, close_scope_with_name(env.module, identifier)}, accumulate: true)
  end

  defp close_scope_and_define_type(env, identifier) do
    attrs = close_scope_with_name(env.module, identifier)
    put_type(env, identifier, attrs)
  end

  defp put_type(env, identifier, attrs) do
    types = Module.get_attribute(env.module, @type_attributes) || []
    Module.put_attribute(env.module, @type_attributes, [{identifier, attrs} | types])
  end

  def get_types(module) do
    types = Module.get_attribute(module, @type_attributes) || []
  end
end