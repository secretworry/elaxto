defmodule Elaxto.Http.Adapter do

  @type response_t :: {:ok, Map.t} | {:error, any}

  @type request_body :: Map.t | String.t

  @type url :: String.t

  @type opts :: any

  @callback ensure_all_started(type :: :application.restart_type, opts) :: {:ok, [atom]}  | {:error, atom}

  @callback init(Keyword.t) :: opts

  @callback get(url, opts) :: response_t

  @callback post(url, request_body, opts) :: response_t

  @callback put(url, request_body, opts) :: response_t

  @callback delete(url, opts) :: response_t

  defmacro __using__(_) do
    quote do
      @behaviour unquote(__MODULE__)

      def init(opts), do: opts

      def ensure_all_started(_, _), do: {:ok, []}

      defoverridable [init: 1, ensure_all_started: 2]
    end
  end
end