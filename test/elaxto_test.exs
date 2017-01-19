defmodule ElaxtoTest do
  use ElaxtoCase

  import Elaxto.Query

  describe "execute/1" do
    test "should reject an invalid action" do

      document_action = %Elaxto.DocumentAction{
        index: :index,
        type: :type,
        document: %{
          "key": "value"
        },
        valid?: false,
        errors: [{"Test error", []}]
      }
      {:error, _} = Elaxto.TestElaxto.execute(document_action)
    end

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

    test "should execute a document action with id" do
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

    test "should reject executing a delete document action without id" do
      {:error, _} = %Elaxto.DocumentAction{
        action: :delete,
        index: :index,
        type: :type,
      } |> Elaxto.TestElaxto.execute
    end

    test "should execute a delete document action" do
      set_response({:ok, %{
        "found" => true,
        "_index" => "product",
        "_type" => "product",
        "_id" => "1",
        "_version" => 2,
        "result" => "deleted",
        "_shards" => %{
          "total" => 2,
          "successful" => 1,
          "failed" => 0
        }}})
      %Elaxto.DocumentAction{
        id: 1,
        action: :delete,
        index: :index,
        type: :type,
      } |> Elaxto.TestElaxto.execute
      assert get_request
          == {:delete, "http://localhost:9200/test_index/type/1", nil}
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

  describe "put/2" do
    test "should be able to put to a raw url" do
      request = %{
        "properties" => %{
          "name" => %{
            "properties" => %{
              "last" => %{
                "type" => "text"
              }
            }
          }
        }
      }
      Elaxto.TestElaxto.put("my_index/_mapping/user", request);
      assert get_request
          == {:put, "http://localhost:9200/my_index/_mapping/user", request}
    end
  end

  describe "delete/2" do
    test "should execute a delete query" do
      Elaxto.TestElaxto.delete(:post)

      assert get_request
          == {:delete, "http://localhost:9200/test_post", nil}
    end

    test "shold execute a delete by query" do
      Elaxto.TestElaxto.delete(:post, %{"query" => %{"match_all" => %{}}})

      assert get_request
          == {:delete, "http://localhost:9200/test_post", %{"query" => %{"match_all" => %{}}}}
    end
  end
end
