defmodule Elaxto.BuilderTest do

  use ExUnit.Case

  alias Elaxto.Schema

  defmodule EmptyElaxto do
    use Elaxto.Builder

    type :empty do
    end
  end

  defmodule ProductElaxto do
    use Elaxto.Builder

    type :product do
      field :name, :keyword
      field :desc, :text
      field :tags, list_of(:text)
    end

    type :brand do
      field :brand_name, :keyword
    end
  end

  defmodule ResolverElaxto do
    use Elaxto.Builder

    type :resolver do
      field :resolved, :text do
        resolver fn _, _ -> "resolved" end
      end
    end
  end

  test "export __elaxto__(type) and __elaxto_types__()" do
    assert EmptyElaxto.__elaxto_type__(:empty) == %Schema.Type{name: :empty, meta: %Schema.Type.Meta{}, fields: %{}}
    assert EmptyElaxto.__elaxto_types__() == %{empty: %Schema.Type{name: :empty, meta: %Schema.Type.Meta{}, fields: %{}}}
  end

  test "define type with fields" do
    assert ProductElaxto.__elaxto_type__(:product) ==
      %Elaxto.Schema.Type{
        name: :product,
        meta: %Elaxto.Schema.Type.Meta{all: false},
        fields: %{
          desc: %Elaxto.Schema.Field{field_type: :text, name: :desc, parameters: %{}, resolver: nil, type: :field},
          name: %Elaxto.Schema.Field{field_type: :keyword, name: :name, parameters: %{}, resolver: nil, type: :field},
          tags: %Elaxto.Schema.Field{field_type: {:list, :text}, name: :tags, parameters: %{}, resolver: nil, type: :field}
        }
      }
    assert ProductElaxto.__elaxto_field__(:name) == %Elaxto.Schema.Field{field_type: :keyword, name: :name, parameters: %{}, resolver: nil, type: :field}
    assert ProductElaxto.__elaxto_fields__() == %{
      desc: %Elaxto.Schema.Field{field_type: :text, name: :desc, parameters: %{}, resolver: nil, type: :field},
      name: %Elaxto.Schema.Field{field_type: :keyword, name: :name, parameters: %{}, resolver: nil, type: :field},
      tags: %Elaxto.Schema.Field{field_type: {:list, :text}, name: :tags, parameters: %{}, resolver: nil, type: :field},
      brand_name: %Elaxto.Schema.Field{field_type: :keyword, name: :brand_name, parameters: %{}, resolver: nil, type: :field}
    }
  end

  test "define type with resolver" do
    %{fields: %{resolved: %{resolver: resolver}}} = ResolverElaxto.__elaxto_type__(:resolver)
    assert resolver.(nil, nil) == "resolved"
  end
end