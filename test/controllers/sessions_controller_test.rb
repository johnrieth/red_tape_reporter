require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:admin_user)
    @password = "Secret1*3*5*" # From fixtures
  end

  test "should get new session form" do
    get new_session_path
    assert_response :success
    assert_select "form"
    assert_select "input[type=email]"
    assert_select "input[type=password]"
  end

  test "should create session with valid credentials" do
    post session_path, params: {
      session: {
        email_address: @user.email_address,
        password: @password
      }
    }

    assert_redirected_to root_path

    # Verify session was created in database
    session = Session.find_by(user_id: @user.id)
    assert session.present?, "Session should be created in database"
  end

  test "should not create session with invalid email" do
    post session_path, params: {
      session: {
        email_address: "nonexistent@example.com",
        password: @password
      }
    }

    assert_redirected_to new_session_path
    assert_equal "Try another email address or password.", flash[:alert]
  end

  test "should not create session with invalid password" do
    initial_session_count = Session.count

    post session_path, params: {
      session: {
        email_address: @user.email_address,
        password: "WrongPassword123!"
      }
    }

    assert_redirected_to new_session_path
    assert_equal "Try another email address or password.", flash[:alert]
    assert_equal initial_session_count, Session.count, "No session should be created"
  end

  test "should normalize email address on login" do
    # Test that email is case-insensitive and strips whitespace
    post session_path, params: {
      session: {
        email_address: "  ADMIN@EXAMPLE.COM  ",
        password: @password
      }
    }

    assert_redirected_to root_path

    # Verify session was created
    session = Session.find_by(user_id: @user.id)
    assert session.present?
  end

  test "should destroy session on logout" do
    # First login
    sign_in_as(@user)

    # Get the session that was created
    session = Session.find_by(user_id: @user.id)
    assert session.present?
    session_id = session.id

    # Then logout
    delete session_path

    assert_redirected_to new_session_path

    # Verify session was destroyed in database
    assert_nil Session.find_by(id: session_id)
  end

  test "should store ip address in session" do
    post session_path, params: {
      session: {
        email_address: @user.email_address,
        password: @password
      }
    }, headers: { "REMOTE_ADDR" => "192.168.1.1" }

    session = Session.find_by(user_id: @user.id)
    assert_equal "192.168.1.1", session.ip_address
  end

  test "should store user agent in session" do
    user_agent = "Mozilla/5.0 (Test Browser)"

    post session_path, params: {
      session: {
        email_address: @user.email_address,
        password: @password
      }
    }, headers: { "HTTP_USER_AGENT" => user_agent }

    session = Session.find_by(user_id: @user.id)
    assert_equal user_agent, session.user_agent
  end

  test "should redirect to return_to url after authentication if set" do
    # Set a return_to in session (simulating being redirected to login)
    get admin_reports_path # This should redirect and set return_to

    # Now login
    post session_path, params: {
      session: {
        email_address: @user.email_address,
        password: @password
      }
    }

    # Should redirect back to admin reports
    assert_redirected_to admin_reports_path
  end

  test "should allow unauthenticated access to new and create actions" do
    get new_session_path
    assert_response :success

    # The create action redirects on failure, not 401
    post session_path, params: {
      session: {
        email_address: "test@example.com",
        password: "wrong"
      }
    }
    assert_response :redirect
  end

  test "login form should be case insensitive" do
    # Rails normalizes email automatically in User model
    post session_path, params: {
      session: {
        email_address: "AdMiN@ExAmPlE.cOm",
        password: @password
      }
    }

    assert_redirected_to root_path

    # Verify session was created
    session = Session.find_by(user_id: @user.id)
    assert session.present?
  end

  test "should create new session record for each login" do
    initial_count = Session.count

    post session_path, params: {
      session: {
        email_address: @user.email_address,
        password: @password
      }
    }

    assert_equal initial_count + 1, Session.count
  end

  test "can access protected pages after login" do
    sign_in_as(@user)
    get admin_reports_path
    assert_response :success
  end

  test "cannot access protected pages without login" do
    get admin_reports_path
    assert_redirected_to new_session_path
  end
end
