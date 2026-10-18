require "test_helper"

class Wiki::GraphsControllerTest < ActionDispatch::IntegrationTest
  test "data returns all articles and links as JSON" do
    a = WikiArticle.create!(title: "Options", summary: "s", body: "See [[Volatility]].", category: "Derivatives")
    b = WikiArticle.find_by(title: "Volatility")

    get wiki_graph_data_path(format: :json)
    assert_response :success

    json = JSON.parse(response.body)
    node_ids = json["nodes"].map { |n| n["id"] }
    assert_includes node_ids, a.id
    assert_includes node_ids, b.id
    assert_includes json["edges"], { "source" => a.id, "target" => b.id }
  end

  test "data scoped to a root slug only includes direct neighbors" do
    a = WikiArticle.create!(title: "Options", summary: "s", body: "See [[Volatility]].", category: "Derivatives")
    WikiArticle.create!(title: "Unrelated", summary: "s", body: "No links.", category: "Misc")

    get wiki_graph_data_path(format: :json, root: a.slug)
    json = JSON.parse(response.body)

    assert_equal 2, json["nodes"].length
    assert_not_includes json["nodes"].map { |n| n["title"] }, "Unrelated"
  end

  test "show renders the graph container" do
    get wiki_graph_path
    assert_response :success
    assert_select "#wiki-graph"
  end
end
