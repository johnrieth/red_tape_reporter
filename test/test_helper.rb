ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...

    # Helper to create valid report parameters
    def valid_report_params
      {
        name: "Test User",
        email: "test@example.com",
        project_description: "Building a new ADU for rental income in my backyard",
        issue_description: "The permit approval process took over 6 months with no clear timeline communicated",
        project_type: "Accessory dwelling unit (ADU)",
        location: "Los Angeles",
        issue_categories: [ "Permits", "Plan review" ],
        departments: [ "Building & Safety" ],
        timeline_impact: "6-12 months",
        financial_impact: "$10,000-$50,000"
      }
    end

    # Helper to sign in as admin for controller tests
    def sign_in_as(user)
      post session_url, params: { session: { email_address: user.email_address, password: "Secret1*3*5*" } }
    end
  end
end

# Integration test helpers
class ActionDispatch::IntegrationTest
  # Helper to sign in during integration tests
  def sign_in_as(user)
    post session_url, params: { session: { email_address: user.email_address, password: "Secret1*3*5*" } }
  end

  # Helper to check if user is signed in
  def signed_in?
    cookies[:session_token].present?
  end
end
