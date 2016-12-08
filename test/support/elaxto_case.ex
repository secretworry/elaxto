defmodule ElaxtoCase do

  use ExUnit.CaseTemplate

  using do
    quote do
      import ElaxtoCase
    end
  end

  setup do
    Elaxto.TestAdapter.reset
  end

  def set_response(response) do
    Elaxto.TestAdapter.set_response(response)
  end

  def get_request do
    Elaxto.TestAdapter.get_request
  end
end