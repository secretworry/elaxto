# Elaxto

The real DSL for ElasticSearch in Elixir

# Why Elaxto

Since ElasticSearch has defined a DSL using JSON, why bother writing another lib to write a DSL
for another DSL? The answer is JSON is too verbose. Especially, the map expression in Elixir
makes the situation worse(`%{}` instead of `{}`, `=>` instead of `:`).

Considering a ElasticSearch query is just a series of nested function calls, why don't we just
use function calls in the Elixir to emulate the ES Query DSL?

Here is a quick compare using a bool query example from [ES Official site](https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-bool-query.html)

Firstly, our function-based DSL

  ```elixir
  query(
    bool(
      must: term(user: "kimchy"),
      filter: term(tag: "tech"),
      must_not: range(age: [from: 10, to: 20]),
      should: [term(tag: "wow"), term(tag: "elasticsearch")],
      minimum_should_match: 1,
      boost: 1.0
    )
  )
  ```
Here the original query expression
  ```javascript
  {
    "query": {
      "bool" : {
        "must" : {
          "term" : { "user" : "kimchy" }
        },
        "filter": {
          "term" : { "tag" : "tech" }
        },
        "must_not" : {
          "range" : {
            "age" : { "from" : 10, "to" : 20 }
          }
        },
        "should" : [
          { "term" : { "tag" : "wow" } },
          { "term" : { "tag" : "elasticsearch" } }
        ],
        "minimum_should_match" : 1,
        "boost" : 1.0
      }
    }
  }
  ```
and the Elixir version
  ```elixir
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
  ```

I think the result is clear enough, our solution wins out with more concise expression, and less LOC.

Besides, we provided a simple ElasticSearch abstraction helping you to organize your ElasticSearch related code.

## Installation

Still under construction, wants to be an early bird?

  Add `elaxto` to your list of dependencies in `mix.exs`:

      ```elixir
      def deps do
        [{:elaxto, github: "secretworry/elaxto", branch: :master}]
      end
      ```

# Usage

## Building Query

Just `import Elaxto.Query` in your module, you can use the macro `query/1` and `suggest/1` to build ElasticSearch query.
  ```elixir
  defmodule MyApp.UserIndex do
    import Elaxto.Query
    def search_by_user_name(user_name) do
      MyApp.Elacto.post({:my_app, :user},
        query(
          term(user_name: ^user_name) # Don't forget to use the escape character ^ here
        )
      )
    end
  end
  ```
Now you can defining ES Query like invoking a bunch of elixir calls, but here's some hint.

  1. Since it's still a elixir call, you can only put the keyword-like args at the tail of args
    To construct a query like this
    ```javascript
    {"query": { "bool": {"boot": 1.0, "must": { "term": {"user": "name"}}}}}
    ```
    instead of adding the `boot` args at the front of the `bool` call, you have to push it to the end of argument list,
    like this
    ```elixir
    query(bool(must: term(user: "name"), boot: 1.0))
    # instead of
    # query(boot: 1.0, bool(must: term(user: "name")))
    ```
  2. Use `^` to escape variables in the query
    ```elixir
    name = "Alice"
    query(term(user_name: ^name))
    ```
  3. Be conscious about how the queries should be composed.
    We can compose two queries in two ways, the first is to let them merge into a list, the second would be composing them
    into a map.
    
    ```elixir
    # We archive the first one through wrapping the two query into an array
    bool(
      should: [term(tag: "elaxto"), term(tag: "woo")]
    )
    # generates: {should: [ {term: {tag: "elaxto"}, {term: {tag: "woo"}]}
    
    # We archive the second on through wrapping the two query into an double-array `[[` and `]]
    bool(
      must: [[term(tag: "elaxto", match(message: "awesome")]]
    )
    # generates: {must: {term: {tag: "elaxto"}, match: {message: "awesome"}}}
    ```

## Send queries to the server

Code for this section is still under *frequently* reconstruction

  1. Define your own `Elaxto.Http.Adapter` or use the provided `Elaxto.Http.Adapters.Maxwell`(thanks to [Maxwell](https://github.com/zhongwencool/maxwell) a awesome http client adapter)
  2. Define a `Elaxto` in your project
    ```elixir
    defmodule MyApp.Elaxto do
      use Elaxto, otp_app: :my_app
    end
    ```
  3. Add configuration for the `Elaxto` in your config file
    ```elixir
    config :my_app, MyApp.Elaxto,
      http_adapter: Elaxto.Http.Adapters.Maxwell
    ```
    you can also pass options to the adapter in the config
    ```elixir
    config :my_app, MyApp.Elaxto,
      http_adapter: {Elaxto.Http.Adapters.Maxwell, [key: value]}
    ```
    
    The available options are
    
    * `http_adapter` - (required) the Http Adapter used for the Elaxto, you can config different adapter for different env
    * `host`         - (optional) the host & port for ElasticSearch server, defaults to `http://localhost:9200`
  4. Now you can use `get/1`, `post/2`, `put/2`, `delete/1` to interact with the server

## Defining index schema

An index schema defines how to create an index, and how to convert models into documents of ES

(To Be Continued)
    

