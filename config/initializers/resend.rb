Resend.api_key = Rails.application.credentials.dig(:resend, :api_key) || ENV['RESEND_API_KEY']
