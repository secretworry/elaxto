defmodule Elaxto.Index do

  alias Elaxto.DocumentAction

  @type response_t :: map
  @type error :: any
  @callback execute(DocumentAction.t) :: {:ok, response_t} | {:error, error}
end