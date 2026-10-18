require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "root shows entry points to wiki, interview, and trade" do
    get root_path
    assert_response :success
    assert_select "a[href=?]", wiki_path
    assert_select "a[href=?]", interview_problems_path
    assert_select "a[href=?]", trade_path
  end
end
