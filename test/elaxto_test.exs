defmodule ElaxtoTest do
  use ElaxtoCase

  import Elaxto.Query

  describe "execute/1" do
    test "should execute a document action without id" do
      set_response({:ok, %{
        "_shards" => %{"failed" => 0, "successful" => 2, "total" => 2},
        "_id" => "6a8ca01c-7896-48e9-81cc-9f70661fcb32", "_index" => "twitter",
        "_type" => "tweet", "_version" => 1, "created" => true,
        "result" => "created"}
      })
      document_action = %Elaxto.DocumentAction{
        index: :index,
        type: :type,
        document: %{
          "key": "value"
        }
      }
      Elaxto.TestElaxto.execute(document_action)
      assert get_request
          == {:post, "http://localhost:9200/test_index/type/", %{key: "value"}}
    end

    test "should execute a document with and id" do
      id = 1
      set_response({:ok, %{
        "_shards" => %{"failed" => 0, "successful" => 2, "total" => 2},
        "_id" => "#{id}", "_index" => "twitter",
        "_type" => "tweet", "_version" => 1, "created" => true,
        "result" => "created"}
      })
      %Elaxto.DocumentAction{
        id: id,
        index: :index,
        type: :type,
        document: %{
          "key": "value"
        }
      } |> Elaxto.TestElaxto.execute
      assert get_request
          == {:post, "http://localhost:9200/test_index/type/1", %{key: "value"}}
    end

    test "should execute a index action" do
      set_response({:ok, %{
        "acknowledged" => true
      }})
      mappings = %{
        "product" => %{
          "name" => %{
            "type" => "text"
          }
        }
      }
      %Elaxto.IndexAction{
        name: :test,
        mappings: mappings
      } |> Elaxto.TestElaxto.execute
      assert get_request
          == {:put, "http://localhost:9200/test_test", %{"mappings" => mappings}}
    end
  end

  describe "post/3" do
    test "should execute a query" do
      Elaxto.TestElaxto.post(:post, query(
        bool(
          must: term(key: "value")
        )
      ))
      assert get_request
          == {:post, "http://localhost:9200/test_post", %{
            "query" => %{
              "bool" => %{
                "must" => %{
                  "term" => %{
                    "key" => "value"
                  }
                }
              }
            }
          }}
    end
  end
end
