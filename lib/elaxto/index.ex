defmodule Elaxto.Index do

  @type opts :: Keyword.t

  @type type :: atom

  @type model :: struct | map

  @callback name() :: atom

  @callback types() :: [atom]

  @callback create(opts) :: Elaxto.IndexAction.t

  @callback index(type, model, opts) :: Elaxto.DocumentAction.t
end