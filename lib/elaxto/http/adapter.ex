defmodule Elaxto.Http.Adapter do

  @type response_t :: {:ok, Map.t} | {:error, any}

  @type request_body :: Map.t | String.t

  @type url :: String.t

  @callback get(url) :: response_t

  @callback post(url, request_body) :: response_t

  @callback put(url, request_body) :: response_t

  @callback delete(url) :: response_t
end