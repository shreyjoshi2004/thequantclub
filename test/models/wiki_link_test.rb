require "test_helper"

class WikiLinkTest < ActiveSupport::TestCase
  test "creates a stub article and a link for an unresolved [[wiki link]]" do
    article = WikiArticle.create!(title: "Options", summary: "s", body: "See [[Delta Hedging]] for more.", category: "Derivatives")

    stub = WikiArticle.find_by(title: "Delta Hedging")
    assert stub.present?
    assert stub.stub?
    assert_equal [stub.id], article.outgoing_links.pluck(:to_article_id)
  end

  test "links to an existing article instead of creating a duplicate" do
    target = WikiArticle.create!(title: "Volatility", summary: "s", body: "b", category: "Risk")
    article = WikiArticle.create!(title: "Options", summary: "s", body: "See [[Volatility]].", category: "Derivatives")

    assert_equal 1, WikiArticle.where(title: "Volatility").count
    assert_equal [target.id], article.outgoing_links.pluck(:to_article_id)
  end

  test "removes a link when the body no longer references it" do
    article = WikiArticle.create!(title: "Options", summary: "s", body: "See [[Volatility]].", category: "Derivatives")
    assert_equal 1, article.outgoing_links.count

    article.update!(body: "No more links here.")
    assert_equal 0, article.reload.outgoing_links.count
  end

  test "backlinked_articles lists articles pointing at this one" do
    target = WikiArticle.create!(title: "Volatility", summary: "s", body: "b", category: "Risk")
    source = WikiArticle.create!(title: "Options", summary: "s", body: "See [[Volatility]].", category: "Derivatives")

    assert_equal [source], target.backlinked_articles
  end
end
