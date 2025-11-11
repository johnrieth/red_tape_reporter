require "test_helper"

class UserTest < ActiveSupport::TestCase
  # ============================================================
  # VALIDATION TESTS
  # ============================================================

  test "should create user with valid attributes" do
    user = User.new(
      email_address: "newuser@example.com",
      password: "SecurePassword123!",
      password_confirmation: "SecurePassword123!"
    )
    assert user.save, "Should save valid user"
  end

  test "should not save user without password" do
    user = User.new(email_address: "test@example.com")
    assert_not user.save, "Should not save user without password"
  end

  test "should authenticate with correct password" do
    user = users(:admin_user)
    assert user.authenticate("Secret1*3*5*"), "Should authenticate with correct password"
  end

  test "should not authenticate with incorrect password" do
    user = users(:admin_user)
    assert_not user.authenticate("WrongPassword"), "Should not authenticate with wrong password"
  end

  # ============================================================
  # EMAIL NORMALIZATION TESTS
  # ============================================================

  test "should normalize email to lowercase" do
    user = User.create!(
      email_address: "TEST@EXAMPLE.COM",
      password: "SecurePassword123!",
      password_confirmation: "SecurePassword123!"
    )
    assert_equal "test@example.com", user.email_address
  end

  test "should strip whitespace from email" do
    user = User.create!(
      email_address: "  test@example.com  ",
      password: "SecurePassword123!",
      password_confirmation: "SecurePassword123!"
    )
    assert_equal "test@example.com", user.email_address
  end

  # ============================================================
  # ASSOCIATION TESTS
  # ============================================================

  test "should have many sessions" do
    user = users(:admin_user)
    assert_respond_to user, :sessions
  end

  test "should destroy dependent sessions when user is destroyed" do
    user = users(:admin_user)
    session = Session.create!(user: user, ip_address: "127.0.0.1", user_agent: "Test")

    assert_difference("Session.count", -1) do
      user.destroy
    end
  end

  # ============================================================
  # ADMIN TESTS
  # ============================================================

  test "admin user should have admin flag set to true" do
    admin = users(:admin_user)
    assert admin.admin?, "Admin user should have admin flag"
  end

  test "regular user should have admin flag set to false" do
    regular = users(:regular_user)
    assert_not regular.admin?, "Regular user should not have admin flag"
  end
end
