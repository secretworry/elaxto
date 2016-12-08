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
  end
end