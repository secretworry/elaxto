Application.put_env(:elaxto, Elaxto.MaxwellElaxto, [
  http_adapter: Elaxto.Http.Adapters.Maxwell
])

defmodule Elaxto.MaxwellElaxto do
  use Elaxto, otp_app: :elaxto
end

defmodule Elaxto.Http.Adapters.MaxwellTest do

  use ExUnit.Case

  def create_test_index do
    {:ok, _} = %Elaxto.IndexAction{
      name: :maxwell,
      mappings: %{
        "test" => %{
          "properties" => %{
            "key" => %{
              "type" => "text"
            }
          }
        }
      }
    } |> Elaxto.MaxwellElaxto.execute
  end

  defp drop_test_index do
    Elaxto.MaxwellElaxto.delete(:maxwell)
  end

  setup do
    create_test_index
    on_exit fn -> drop_test_index end
  end

  test "create test index" do
  end
end