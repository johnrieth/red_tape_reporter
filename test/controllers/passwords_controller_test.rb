require "test_helper"

class PasswordsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:admin_user)
  end

  test "should get new password reset form" do
    get new_password_path
    assert_response :success
    assert_select "form"
  end

  test "should send password reset email for existing user" do
    assert_enqueued_emails 1 do
      post passwords_path, params: { email_address: @user.email_address }
    end

    assert_redirected_to new_session_path
    assert_equal "Password reset instructions sent (if user with that email address exists).", flash[:notice]
  end

  test "should not leak user existence for non-existent email" do
    # Test timing attack prevention - should respond the same way
    post passwords_path, params: { email_address: "nonexistent@example.com" }

    assert_redirected_to new_session_path
    assert_equal "Password reset instructions sent (if user with that email address exists).", flash[:notice]
  end

  test "should not send email for non-existent user" do
    assert_no_enqueued_emails do
      post passwords_path, params: { email_address: "nonexistent@example.com" }
    end
  end

  test "should get edit password form with valid token" do
    token = @user.generate_token_for(:password_reset)
    get edit_password_path(token: token)
    assert_response :success
    assert_select "form"
  end

  test "should redirect with alert for invalid token" do
    get edit_password_path(token: "invalid_token")
    assert_redirected_to new_password_path
    assert_equal "Password reset link is invalid or has expired.", flash[:alert]
  end

  test "should update password with valid token and matching passwords" do
    token = @user.generate_token_for(:password_reset)
    new_password = "NewSecure1*3*5*"

    patch password_path(token: token), params: {
      password: new_password,
      password_confirmation: new_password
    }

    assert_redirected_to new_session_path
    assert_equal "Password has been reset.", flash[:notice]

    # Verify user can login with new password
    @user.reload
    assert @user.authenticate(new_password)
  end

  test "should not update password with mismatched passwords" do
    token = @user.generate_token_for(:password_reset)

    patch password_path(token: token), params: {
      password: "NewPassword123!",
      password_confirmation: "DifferentPassword123!"
    }

    assert_redirected_to edit_password_path(token: token)
    assert_equal "Passwords did not match.", flash[:alert]
  end

  test "should not update password with invalid token" do
    patch password_path(token: "invalid_token"), params: {
      password: "NewPassword123!",
      password_confirmation: "NewPassword123!"
    }

    assert_redirected_to new_password_path
    assert_equal "Password reset link is invalid or has expired.", flash[:alert]
  end

  test "password reset form should be accessible without authentication" do
    # Ensure the routes are accessible without login
    get new_password_path
    assert_response :success
    assert_not session[:user_id]
  end
end
