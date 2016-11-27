defmodule Elaxto do
  @type index_return_t :: map

  @type error :: error
  @type opts :: Keyword.t
  @type document_type :: atom
  @type data :: map

  @callback index(document_type, data, opts) :: Elaxtor.DocumentAction.t
end
