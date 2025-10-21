# lib/tasks/admin.rake
namespace :admin do
  desc "Create an admin user"
  task create: :environment do
    email = ENV.fetch("EMAIL") do
      puts "ERROR: EMAIL environment variable is required"
      puts "Usage: EMAIL=admin@example.com PASSWORD=secure123 rails admin:create"
      exit 1
    end

    password = ENV.fetch("PASSWORD") do
      puts "ERROR: PASSWORD environment variable is required"
      puts "Usage: EMAIL=admin@example.com PASSWORD=secure123 rails admin:create"
      exit 1
    end

    if password.length < 8
      puts "ERROR: Password must be at least 8 characters long"
      exit 1
    end

    begin
      user = User.create!(
        email_address: email,
        password: password,
        admin: true
      )
      puts "✓ Admin user created successfully!"
      puts "  Email: #{user.email_address}"
      puts "  Admin: #{user.admin}"
      puts ""
      puts "You can now log in at /session/new"
    rescue ActiveRecord::RecordInvalid => e
      puts "ERROR: Failed to create admin user"
      puts e.message
      exit 1
    end
  end

  desc "List all admin users"
  task list: :environment do
    admins = User.where(admin: true)

    if admins.any?
      puts "Admin Users:"
      puts "-" * 60
      admins.each do |admin|
        puts "  ID: #{admin.id}"
        puts "  Email: #{admin.email_address}"
        puts "  Created: #{admin.created_at.strftime('%Y-%m-%d %H:%M:%S')}"
        puts "-" * 60
      end
      puts "Total: #{admins.count} admin user(s)"
    else
      puts "No admin users found."
      puts "Create one with: EMAIL=admin@example.com PASSWORD=secure123 rails admin:create"
    end
  end

  desc "Promote existing user to admin"
  task :promote, [ :email ] => :environment do |t, args|
    if args.email.blank?
      puts "ERROR: Email address is required"
      puts "Usage: rails admin:promote[user@example.com]"
      exit 1
    end

    user = User.find_by(email_address: args.email)

    if user.nil?
      puts "ERROR: User with email '#{args.email}' not found"
      exit 1
    end

    if user.admin?
      puts "User '#{user.email_address}' is already an admin"
      exit 0
    end

    user.update!(admin: true)
    puts "✓ User '#{user.email_address}' promoted to admin"
  end

  desc "Revoke admin privileges from user"
  task :demote, [ :email ] => :environment do |t, args|
    if args.email.blank?
      puts "ERROR: Email address is required"
      puts "Usage: rails admin:demote[user@example.com]"
      exit 1
    end

    user = User.find_by(email_address: args.email)

    if user.nil?
      puts "ERROR: User with email '#{args.email}' not found"
      exit 1
    end

    if !user.admin?
      puts "User '#{user.email_address}' is not an admin"
      exit 0
    end

    # Safety check: don't demote the last admin
    admin_count = User.where(admin: true).count
    if admin_count == 1
      puts "ERROR: Cannot demote the last admin user"
      puts "Create another admin first before demoting this user"
      exit 1
    end

    user.update!(admin: false)
    puts "✓ Admin privileges revoked from '#{user.email_address}'"
  end
end
