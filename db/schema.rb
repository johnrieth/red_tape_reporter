# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_12_01_020747) do
  create_table "audit_logs", force: :cascade do |t|
    t.integer "report_id", null: false
    t.integer "user_id", null: false
    t.integer "action_type", null: false
    t.string "ip_address"
    t.text "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["action_type"], name: "index_audit_logs_on_action_type"
    t.index ["report_id", "created_at"], name: "index_audit_logs_on_report_id_and_created_at"
    t.index ["report_id"], name: "index_audit_logs_on_report_id"
    t.index ["user_id", "created_at"], name: "index_audit_logs_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_audit_logs_on_user_id"
  end

  create_table "comments", force: :cascade do |t|
    t.integer "report_id", null: false
    t.text "content", null: false
    t.string "commenter_token", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["report_id", "created_at"], name: "index_comments_on_report_id_and_created_at"
    t.index ["report_id"], name: "index_comments_on_report_id"
  end

  create_table "issues", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.integer "category"
    t.integer "status"
    t.integer "submitted_by_id", null: false
    t.boolean "is_public"
    t.json "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["submitted_by_id"], name: "index_issues_on_submitted_by_id"
  end

  create_table "reports", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.text "project_description"
    t.text "issue_description"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "project_type"
    t.string "location"
    t.text "issue_categories"
    t.text "departments"
    t.string "timeline_impact"
    t.string "financial_impact"
    t.boolean "anonymous", default: false, null: false
    t.string "verification_token"
    t.datetime "verified_at"
    t.datetime "approved_at"
    t.datetime "deleted_at"
    t.text "solution_ideas"
    t.boolean "share_publicly", default: false, null: false
    t.index ["approved_at"], name: "index_reports_on_approved_at"
    t.index ["deleted_at"], name: "index_reports_on_deleted_at"
    t.index ["verification_token"], name: "index_reports_on_verification_token", unique: true
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "support_comments", force: :cascade do |t|
    t.integer "support_id", null: false
    t.integer "user_id", null: false
    t.text "content"
    t.integer "visibility"
    t.json "impact_data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["support_id"], name: "index_support_comments_on_support_id"
    t.index ["user_id"], name: "index_support_comments_on_user_id"
  end

  create_table "supports", force: :cascade do |t|
    t.integer "issue_id", null: false
    t.integer "user_id", null: false
    t.integer "visibility"
    t.string "anonymity_token"
    t.decimal "estimated_cost"
    t.string "project_reference"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["issue_id"], name: "index_supports_on_issue_id"
    t.index ["user_id"], name: "index_supports_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "admin", default: false, null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  create_table "votes", force: :cascade do |t|
    t.integer "report_id", null: false
    t.string "voter_token", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["report_id", "voter_token"], name: "index_votes_on_report_id_and_voter_token", unique: true
    t.index ["report_id"], name: "index_votes_on_report_id"
  end

  add_foreign_key "audit_logs", "reports"
  add_foreign_key "audit_logs", "users"
  add_foreign_key "comments", "reports"
  add_foreign_key "issues", "users", column: "submitted_by_id"
  add_foreign_key "sessions", "users"
  add_foreign_key "support_comments", "supports"
  add_foreign_key "support_comments", "users"
  add_foreign_key "supports", "issues"
  add_foreign_key "supports", "users"
  add_foreign_key "votes", "reports"
end
