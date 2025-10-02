require "test_helper"

class Admin::ReportsControllerTest < ActionDispatch::IntegrationTest
  test "should redirect non-admin to login" do
    get admin_reports_path
    assert_redirected_to new_session_path
  end
end
