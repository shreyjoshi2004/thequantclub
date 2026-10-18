require "test_helper"

class Wiki::BodyRendererTest < ActiveSupport::TestCase
  test "renders paragraphs and headings with ids" do
    result = Wiki::BodyRenderer.render("Intro paragraph.\n\n## Background\n\nMore text.")

    assert_includes result.html, "<p>Intro paragraph.</p>"
    assert_includes result.html, '<h2 id="background">Background</h2>'
    assert_equal [["Background", "background"]], result.headings.map { |h| [h.text, h.id] }
  end

  test "renders a resolved [[link]] with the target's slug" do
    target = WikiArticle.create!(title: "Volatility", summary: "s", body: "b", category: "Risk")
    result = Wiki::BodyRenderer.render("See [[Volatility]].")

    assert_includes result.html, %(<a href="/wiki/#{target.slug}" class="wiki-link">Volatility</a>)
  end

  test "renders a stub [[link]] with the stub styling class" do
    WikiArticle.create!(title: "Delta Hedging", summary: "", body: "", category: "")
    result = Wiki::BodyRenderer.render("See [[Delta Hedging]].")

    assert_includes result.html, "wiki-link--stub"
  end

  test "escapes HTML in the body" do
    result = Wiki::BodyRenderer.render("<script>alert(1)</script>")
    assert_includes result.html, "&lt;script&gt;"
    assert_not_includes result.html, "<script>"
  end
end
