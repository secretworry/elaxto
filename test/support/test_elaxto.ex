defmodule Elaxto.TestAdapter do
  use Elaxto.Http.Adapter

  def start_link do
    Agent.start_link(fn -> %{request: nil, response: nil} end, name: __MODULE__)
  end

  def get(url, _opts) do
    get_response_with({:get, url})
  end

  def post(url, body, _opts) do
    get_response_with({:post, url, body})
  end

  def put(url, body, _opts) do
    get_response_with({:put, url, body})
  end

  def delete(url, _opts) do
    get_response_with({:delete, url})
  end

  def get_response_with(request) do
    Agent.get_and_update(__MODULE__, fn
      state ->
        {state[:response], %{state | request: request}}
    end)
  end

  def set_response(response) do
    Agent.update(__MODULE__, &(Map.put(&1, :response, response)))
  end

  def get_request do
    Agent.get(__MODULE__, &(&1[:request]))
  end

  def reset do
    Agent.update(__MODULE__, fn _ -> %{request: nil, response: nil} end)
  end
end

Application.put_env(:elaxto, Elaxto.TestElaxto, [
  http_adapter: Elaxto.TestAdapter,
  prefix: "test_"
])

defmodule Elaxto.TestElaxto do
  @moduledoc false
  use Elaxto, otp_app: :elaxto
end