require "test_helper"

class WikiArticleTest < ActiveSupport::TestCase
  test "assigns a slug from the title on save" do
    article = WikiArticle.create!(title: "Black-Scholes Model", summary: "s", body: "b", category: "Derivatives")
    assert_equal "black-scholes-model", article.slug
  end

  test "rejects a case-variant duplicate title" do
    WikiArticle.create!(title: "Options", summary: "s", body: "b", category: "Derivatives")
    duplicate = WikiArticle.new(title: "options", summary: "s2", body: "b2", category: "Derivatives")

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:title], "has already been taken"
  end

  test "requires a title" do
    article = WikiArticle.new(summary: "s", body: "b")
    assert_not article.valid?
  end

  test "to_param returns the slug" do
    article = WikiArticle.create!(title: "Volatility", summary: "s", body: "b", category: "Risk")
    assert_equal article.slug, article.to_param
  end

  test "stub? is true for an article with no body" do
    stub = WikiArticle.create!(title: "Delta Hedging", summary: "", body: "", category: "")
    assert stub.stub?
  end
end
