defmodule Elaxto do

  @type t :: module

  @type action ::
    Elaxto.DocumentAction.t
  | Elaxto.IndexAction.t

  @type response_t :: {:ok, Map.t} | {:error, any}

  @type index :: atom

  @type queriable_t :: atom | {atom, atom} | {atom, [atom]} | {atom, atom, any} | [atom] | String.t

  @type query :: Map.t

  @type opts :: Keyword.t

  @callback execute(action) :: response_t

  @callback get(queriable_t, opts) :: response_t
  @callback post(queriable_t, query, opts) :: response_t
  @callback put(queriable_t, query, opts) :: response_t
  @callback delete(queriable_t, opts) :: response_t

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      require Elaxto
      {otp_app, http_adapter, host, config} = Elaxto.parse_config(__MODULE__, opts)
      @otp_app otp_app
      @http_adapter http_adapter
      @config config
      @host host

      def __http_adapter__, do: @http_adapter
      
      def __host__, do: @host
      
      def __config__, do: @config

      def _build_request_uri(uri) do
        URI.merge(@host, uri) |> URI.to_string
      end

      defp ensure_valid_action(action) do
        if action.valid? do
          {:ok, action}
        else
          {:error, action}
        end
      end

      def execute(%Elaxto.DocumentAction{action: :index} = document_action) do
        with {:ok, document_action} <- ensure_valid_action(document_action) do
          queriable = Elaxto.RequestBuilder.to_queriable(document_action)
          query = Elaxto.RequestBuilder.to_query(document_action)
          post(queriable, query, document_action.opts)
        end
      end

      def execute(%Elaxto.DocumentAction{action: :delete, id: nil} = document_action) do
        {:error, "id for Elaxto.DocumentAction with delete action should not be nil"}
      end

      def execute(%Elaxto.DocumentAction{action: :delete} = document_action) do
        with {:ok, document_action} <- ensure_valid_action(document_action) do
          queriable = Elaxto.RequestBuilder.to_queriable(document_action)
          delete(queriable, document_action.opts)
        end
      end

      def execute(%Elaxto.IndexAction{} = index_action) do
        with {:ok, index_action} <- ensure_valid_action(index_action) do
          queriable = Elaxto.RequestBuilder.to_queriable(index_action)
          query = Elaxto.RequestBuilder.to_query(index_action)
          put(queriable, query, index_action.opts)
        end
      end

      def get(queriable, opts \\ []) do
        uri = Elaxto.RequestBuilder.queriable_to_uri(@config, queriable, opts)
        request_uri = _build_request_uri(uri)
        Elaxto.call_http_adapter(@http_adapter, :get, [request_uri])
      end

      def post(queriable, query, opts \\ []) do
        uri = Elaxto.RequestBuilder.queriable_to_uri(@config, queriable, opts)
        request_uri = _build_request_uri(uri)
        Elaxto.call_http_adapter(@http_adapter, :post, [request_uri, query])
      end

      def put(queriable, query, opts \\ []) do
        uri = Elaxto.RequestBuilder.queriable_to_uri(@config, queriable, opts)
        request_uri = _build_request_uri(uri)
        Elaxto.call_http_adapter(@http_adapter, :put, [request_uri, query])
      end

      def delete(queriable, opts \\ []) do
        uri = Elaxto.RequestBuilder.queriable_to_uri(@config, queriable, opts)
        request_uri = _build_request_uri(uri)
        Elaxto.call_http_adapter(@http_adapter, :delete, [request_uri])
      end

      defmodule ScanEnum do
        require Elixir.Elaxto.Query
        alias Elixir.Elaxto.Query
        defstruct queriable: nil, query: nil, scroll: nil, opts: opts, scroll_id: nil, done: false

        def new(queriable, query, scroll, opts) do
          %__MODULE__{queriable: queriable, query: query, opts: opts, scroll: scroll}
        end

        defimpl Enumerable do
          defp outer_scope, do: unquote(Module.split(__MODULE__) |> tl |> Enum.reverse |> tl |> Enum.reverse |> Module.concat)
          def count(_), do: {:error, __MODULE__}
          def member?(_, _), do: {:error, __MODULE__}

          def reduce(_,     {:halt, acc}, _fun), do: {:halted, acc}
          def reduce(enum,  {:suspend, acc}, fun), do: {:suspended, acc, &reduce(enum, &1, fun)}
          def reduce(%{done: true}, {:cont, acc}, _fun), do: {:done, acc}
          def reduce(enum, {:cont, acc}, fun) do
            case Elaxto.call_http_adapter(outer_scope.__http_adapter__, :post, [request_uri(enum), query(enum)]) do
              {:ok, response} ->
                done = case response["hits"]["hits"] do
                  [_|_] -> false
                  _ -> true
                end
                scroll_id = response["_scroll_id"]
                reduce(%{enum | scroll_id: scroll_id, done: done}, fun.(response, acc), fun)
              {:error, err} ->
                {:halted, acc}
            end
          end

          defp request_uri(%{scroll_id: nil, queriable: queriable, query: query, opts: opts, scroll: scroll}) do
            uri = Elaxto.RequestBuilder.queriable_to_uri(outer_scope.__config__, queriable, Keyword.put(opts, :scroll, scroll))
            outer_scope._build_request_uri(uri)
          end

          defp request_uri(%{opts: opts}) do
            uri = Elaxto.RequestBuilder.queriable_to_uri(outer_scope.__config__, {"_search", "scroll"}, opts)
            outer_scope._build_request_uri(uri)
          end

          defp query(%{scroll_id: nil, query: query}), do: query
          defp query(%{scroll_id: scroll_id, scroll: scroll}), do: %{"scroll" => scroll, "scroll_id" => scroll_id}
        end
      end

      def scan(queriable, query, scroll, opts \\ []) do
        ScanEnum.new(queriable, query, scroll, opts)
      end

    end
  end

  def call_http_adapter({adapter, opts}, method, args) do
    args = args ++ [opts]
    apply(adapter, method, args)
  end

  def parse_config(module, opts) do
    otp_app = Keyword.fetch!(opts, :otp_app)
    config = Application.get_env(otp_app, module, [])
    http_adapter = opts[:http_adapter] || config[:http_adapter]
    host = opts[:host] || config[:host] || "http://localhost:9200"

    unless http_adapter do
      raise ArgumentError, "missing :http_adapter configuration in config #{inspect otp_app}, #{inspect module}"
    end
    {otp_app, init_http_adapter(http_adapter), host, config |> Enum.into(%{})}
  end

  defp init_http_adapter({http_adapter, opts}) do
    {http_adapter, http_adapter.init(opts)}
  end

  defp init_http_adapter(http_adapter) when is_atom(http_adapter) do
    {http_adapter, http_adapter.init([])}
  end

end
