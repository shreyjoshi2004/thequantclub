require "test_helper"

class Wiki::ArticlesControllerTest < ActionDispatch::IntegrationTest
  test "index shows categories and recent articles" do
    WikiArticle.create!(title: "Options", summary: "An option contract.", body: "b", category: "Derivatives")

    get wiki_path
    assert_response :success
    assert_select "h3", text: "Derivatives"
  end

  test "show renders the article body and backlinks" do
    target = WikiArticle.create!(title: "Volatility", summary: "s", body: "b", category: "Risk")
    WikiArticle.create!(title: "Options", summary: "s", body: "See [[Volatility]].", category: "Derivatives")

    get wiki_article_path(target)
    assert_response :success
    assert_select "h2", text: "Articles that link here"
    assert_select "a", text: "Options"
  end

  test "show renders a stub article without erroring" do
    WikiArticle.create!(title: "Options", summary: "s", body: "See [[Delta Hedging]].", category: "Derivatives")
    stub = WikiArticle.find_by(title: "Delta Hedging")

    get wiki_article_path(stub)
    assert_response :success
    assert_select "h1", text: "Delta Hedging"
  end

  test "search finds articles by title or body" do
    WikiArticle.create!(title: "Market Making", summary: "s", body: "quotes both sides", category: "Market Structure")

    get wiki_search_path(q: "quotes")
    assert_select ".wiki-search-result", count: 1
  end

  test "search with a blank query returns no results" do
    WikiArticle.create!(title: "Options", summary: "s", body: "b", category: "Derivatives")

    get wiki_search_path(q: "")
    assert_response :success
    assert_select ".wiki-search-result", count: 0
  end

  test "create saves a valid article and redirects to it" do
    assert_difference -> { WikiArticle.count }, 1 do
      post wiki_articles_path, params: { wiki_article: { title: "Risk Neutral Pricing", summary: "s", body: "b", category: "Derivatives" } }
    end
    assert_redirected_to wiki_article_path(WikiArticle.last)
  end

  test "create re-renders the form with errors when invalid" do
    post wiki_articles_path, params: { wiki_article: { title: "", summary: "s", body: "b", category: "Derivatives" } }
    assert_response :unprocessable_entity
  end

  test "update saves changes to an existing article" do
    article = WikiArticle.create!(title: "Options", summary: "old", body: "b", category: "Derivatives")
    patch wiki_article_path(article), params: { wiki_article: { summary: "new summary" } }
    assert_redirected_to wiki_article_path(article.reload)
    assert_equal "new summary", article.summary
  end
end
