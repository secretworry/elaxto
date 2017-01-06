defmodule Elaxto.Query.BuilderTest do
  use ExUnit.Case

  import Elaxto.Query.Builder

  test "should support converting from a function call to map" do
    ast = quote do: foo()

    assert build(ast)
       == quote do: %{"foo" => %{}}
  end

  test "should support converting function params" do
    ast = quote do: foo(bar: "bar", tar: "tar")
    assert build(ast)
        == quote do: %{"foo" => %{"bar" => "bar", "tar" => "tar"}}
  end

  test "should support nested query" do
    ast = quote do: foo(bar: "bar", tar: term(key: "value"))
    assert build(ast)
        == quote do: %{"foo" => %{"bar" => "bar", "tar" => %{"term" => %{"key" => "value"}}}}
  end

  test "should support merging calls" do
    ast = quote do: foo(tar: [[bar(key: "value"), boo(key: "value")]])
    assert build(ast)
        == quote do: %{"foo" => %{"tar" => %{"boo" => %{"key" => "value"}, "bar" => %{"key" => "value"}}}}
  end

  test "should support escaping values" do
    ast = quote do: foo(tar: ^value)
    assert build(ast)
        == quote do: %{"foo" => %{"tar" => value}}
  end

  test "should support mix call and keyword in call params" do
    ast = quote do: foo(term(name: "name"), text: "search term")
    assert build(ast)
        == quote do: %{"foo" => %{"term" => %{"name" => "name"}, "text" => "search term"}}
  end

  test "should support mix call and constants in call params" do
    ast = quote do: foo(term(name: "name"), "search term")
    assert build(ast)
        == quote do: %{"foo" => [%{"term" => %{"name" => "name"}}, "search term"]}
  end

  test "should support convert boolean values" do
    ast = quote do: foo(bool: true)
    assert build(ast)
        == quote do: %{"foo" => %{"bool" => true}}
  end
end