defmodule Elaxto.QueryTest do
  use ExUnit.Case
  import Elaxto.Query

  describe "query/1" do
    test "bool query" do
      assert query(
        bool(
          must: term(user: "kimchy"),
          filter: term(tag: "tech"),
          must_not: range(age: [from: 10, to: 20]),
          should: [term(tag: "wow"), term(tag: "elasticsearch")],
          minimum_should_match: 1,
          boost: 1.0
        )
      ) ==
      %{"query"=> %{
          "bool" => %{
            "must" => %{
              "term" => %{ "user" => "kimchy" }
            },
            "filter"=> %{
              "term" => %{ "tag" => "tech" }
            },
            "must_not" => %{
              "range" => %{
                "age" => %{ "from" => 10, "to" => 20 }
              }
            },
            "should" => [
              %{ "term" => %{ "tag" => "wow" } },
              %{ "term" => %{ "tag" => "elasticsearch" } }
            ],
            "minimum_should_match" => 1,
            "boost" => 1.0
          }
        }
      }
    end

    test "dis_max query" do
      assert query(
        dis_max(
          tie_breaker: 0.7,
          boost: 1.2,
          queries: [term(age: 34), term(age: 35)]
        )
      ) ==
      %{"query"=> %{
        "dis_max" => %{
          "tie_breaker" => 0.7,
            "boost" => 1.2,
            "queries" => [%{
              "term" => %{ "age" => 34 }
            }, %{
              "term" => %{ "age" => 35 }
            }]}}}
    end

    test "nested query" do
      assert query(
        nested(
          path: "obj1",
          score_mode: "avg",
          query: bool(
            must: [match("obj1.name": "blue"), range("obj1.count": [gt: 5])]
          )
        )
      ) ==
      %{"query"=> %{
        "nested" => %{
          "path" => "obj1",
          "score_mode" => "avg",
          "query" => %{
            "bool" => %{
              "must" => [
              %{ "match" => %{"obj1.name" => "blue"} },
              %{ "range" => %{"obj1.count" => %{"gt" => 5}} }
              ]}
            }
          }
        }
      }
    end

    test "escape complex fields" do
      query = "query"
      assert query(
        multi_match(
          query: ^query,
          fields: ^["field0.raw", "field1.raw"]
        )
      ) == %{"query" => %{
        "multi_match" => %{
          "query" => "query",
          "fields" => ["field0.raw", "field1.raw"]
        }
      }}
    end
  end


  describe "suggest/1" do
    test "smoke case" do
      assert suggest(
        my_suggestion(
          term(field: "message"),
          text: "trying out Elasticsearch"
        )
      ) == %{
        "suggest" => %{
          "my_suggestion" => %{
            "text" => "trying out Elasticsearch",
            "term" => %{
              "field" => "message"
            }
          }
        }
      }
    end

    test "should be able to merge maps into maps" do
      assert suggest(
        user_suggest: [
          prefix: "prefix",
          complection: [field: "suggest"]
        ]
      ) == %{
        "suggest" => %{
          "user_suggest" => %{
            "prefix" => "prefix",
            "complection" => %{
              "field" => "suggest"
            }
          }
        }
      }
    end
  end

  describe "aggregations/1" do
    test "smoke case" do
      assert aggregations(
        red_products(
          filter(term(color: "red")),
          aggs(
            avg_price(avg(field: "price"))
          )
        )
      ) == %{
        "aggs" => %{
          "red_products" => %{
            "filter" => %{ "term" => %{ "color" => "red" } },
            "aggs" => %{
              "avg_price" => %{ "avg" => %{ "field" => "price"} }
            }
          }
        }
      }
    end
  end

  describe "sort/1" do
    test "smoke case" do
      assert sort(["offer.price": %{mode: "avg", order: "asc", nested_path: "offer", nested_filter: term("offer.color": "blue")}])
          == %{
            "sort" => [%{
              "offer.price" => %{
                "mode" => "avg",
                "order" => "asc",
                "nested_path" => "offer",
                "nested_filter" => %{
                  "term" => %{
                    "offer.color" => "blue"
                  }
                }
              }
            }]
          }
    end
  end

  describe "merge/2" do
    test "should merge without error" do
      query1 = query(
        bool(
          must: term(user: "kimchy")
        )
      )

      query2 = query(
        bool(
          must: term(user: "remy")
        )
      )

      assert merge(query1, query2)
          == %{"query" =>
                %{"bool" =>
                  %{"must" =>
                    %{"term" =>
                      %{"user" => ["kimchy", "remy"]}}}}}
    end
  end

  describe "&&&/2" do
    test "should merge without error" do
      query1 = query(
        bool(
          must: term(user: "kimchy")
        )
      )

      query2 = query(
        bool(
          must: term(user: "remy")
        )
      )

      assert (query1 &&& query2)
          == %{"query" =>
                %{"bool" =>
                  %{"must" =>
                    %{"term" =>
                      %{"user" => ["kimchy", "remy"]}}}}}

    end
  end
end