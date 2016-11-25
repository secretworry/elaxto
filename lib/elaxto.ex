defmodule Elaxto do
  @type index_return_t :: map

  @type error :: error
  @type opts :: Keyword.t

  @callback index(Ecto.Schema.t, opts) :: Elaxtor.DocumentAction.t
end
