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

ActiveRecord::Schema[7.0].define(version: 2022_07_01_155419) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "controlled_vocabulary_reference_codes", force: :cascade do |t|
    t.bigint "reference_table_id"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["reference_table_id"], name: "index_reference_codes_on_reference_table_id"
  end

  create_table "controlled_vocabulary_reference_tables", force: :cascade do |t|
    t.string "name"
    t.string "key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "controlled_vocabulary_references", force: :cascade do |t|
    t.bigint "reference_code_id", null: false
    t.string "referrable_type", null: false
    t.bigint "referrable_id", null: false
    t.string "key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["reference_code_id"], name: "index_references_on_reference_code_id"
    t.index ["referrable_type", "referrable_id"], name: "index_references_on_referrable"
  end

  create_table "organizations", force: :cascade do |t|
    t.string "name"
    t.string "location"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "projects", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.string "uid"
    t.string "name"
    t.text "description"
    t.string "api_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_projects_on_organization_id"
  end

  create_table "user_organizations", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "organization_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_user_organizations_on_organization_id"
    t.index ["user_id"], name: "index_user_organizations_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.string "password_digest"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "admin", default: false
  end

  add_foreign_key "projects", "organizations"
  add_foreign_key "user_organizations", "organizations"
  add_foreign_key "user_organizations", "users"
end
