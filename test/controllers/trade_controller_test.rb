require "test_helper"

class TradeControllerTest < ActionDispatch::IntegrationTest
  test "index renders a coming-soon placeholder" do
    get trade_path
    assert_response :success
    assert_select "h1", text: "Trade"
  end
end
