defmodule Elaxto.BuilderTest do

  use ExUnit.Case

  alias Elaxto.Schema

  defmodule EmptyElaxto do
    use Elaxto.Builder

    type :empty do
    end
  end

  test "export __elaxto__(:type)" do
    assert EmptyElaxto.__elaxto__(:type) == %Schema.Type{name: :empty, meta: %Schema.Type.Meta{}, fields: []}
  end
end