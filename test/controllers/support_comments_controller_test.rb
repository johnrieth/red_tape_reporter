require "test_helper"

class SupportCommentsControllerTest < ActionDispatch::IntegrationTest
  test "should get create" do
    get support_comments_create_url
    assert_response :success
  end
end
