if Code.ensure_loaded?(Maxwell) do
defmodule Elaxto.Http.Adapters.Maxwell do
  @behaviour Elaxto.Http.Adapter

  alias __MODULE__

  def get(url) do
    Maxwell.Delegator.do_get(url) |> process_response
  end

  def post(url, body) do
    Maxwell.Delegator.do_post(url, body) |> process_response
  end

  def put(url, body) do
    Maxwell.Delegator.do_put(url, body) |> process_response
  end

  def delete(url) do
    Maxwell.Delegator.do_delete(url) |> process_response
  end

  defp process_response({:ok, %Elixir.Maxwell.Conn{status: status} = conn}) when status in 200..299 do
    {:ok, Elixir.Maxwell.Conn.get_resp_body(conn)}
  end

  defp process_response({:ok, %Elixir.Maxwell.Conn{status: 404} = conn}) do
    {:error, {:not_found, Elixir.Maxwell.Conn.get_resp_body(conn)}}
  end

  defp process_response({:ok, conn}) do
    {:error, {:illegal_response, Elixir.Maxwell.Conn.get_resp_body(conn)}}
  end

  defp process_response({:error, reason, _conn}) do
    {:error, reason}
  end

  defmodule Delegator do
    use Elixir.Maxwell.Builder, ~w{get post put delete}a

    middleware Elixir.Maxwell.Middleware.Opts, [connect_timeout: 3000]
    middleware Elixir.Maxwell.Middleware.Json
    adapter Elixir.Maxwell.Adapter.Ibrowse

    def do_get(url) do
      Elixir.Maxwell.Conn.new(url) |> get
    end

    def do_post(url, body) do
      Elixir.Maxwell.Conn.new(url) |> put_req_body(body) |> post
    end

    def do_put(url, body) do
      Elixir.Maxwell.Conn.new(url) |> put_req_body(body) |> put
    end

    def do_delete(url) do
      Elixir.Maxwell.Conn.new(url) |> delete
    end
  end
end
end