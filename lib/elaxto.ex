defmodule Elaxto do

  @type action ::
    Elaxto.DocumentAction.t
  | Elaxto.IndexAction.t
  | Elaxto.SearchAction.t

  @type response_t :: {:ok, Map.t} | {:error, any}

  @type queriable_t :: atom | {atom, atom} | {atom, [atom]}

  @type query :: Map.t

  @callback execute(action) :: response_t

  @callback query(queriable_t, query) :: response_t
end
