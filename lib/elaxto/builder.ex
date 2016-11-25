defmodule Elaxto.Builder do
  @moduledoc false

  defmacro __using__(opts) do
    quote do
      import Elaxto.Builder.Type
      @before_compile Elaxto.Builder
    end
  end

  defmacro __before_compile__(env) do
  end
end