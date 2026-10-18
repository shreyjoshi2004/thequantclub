require "test_helper"

class Wiki::LinkParserTest < ActiveSupport::TestCase
  test "extracts unique titles from [[wiki links]] in order" do
    body = "See [[Delta Hedging]] and [[Options]], also [[Delta Hedging]] again."
    assert_equal ["Delta Hedging", "Options"], Wiki::LinkParser.titles_in(body)
  end

  test "returns an empty array when there are no links" do
    assert_equal [], Wiki::LinkParser.titles_in("Plain text, no links.")
  end
end
