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

ActiveRecord::Schema[8.1].define(version: 2026_05_15_120300) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "accounts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "account_type", null: false
    t.string "base_currency", null: false
    t.datetime "created_at", null: false
    t.string "status", null: false
    t.datetime "updated_at", null: false
    t.index ["status"], name: "index_accounts_on_status"
    t.check_constraint "account_type::text = ANY (ARRAY['user'::character varying, 'treasury'::character varying, 'system'::character varying]::text[])", name: "accounts_account_type_check"
    t.check_constraint "status::text = ANY (ARRAY['pending'::character varying, 'active'::character varying, 'suspended'::character varying]::text[])", name: "accounts_status_check"
  end

  create_table "balances", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.string "asset_code", null: false
    t.decimal "available_amount", precision: 20, scale: 8, default: "0.0", null: false
    t.decimal "borrowed_amount", precision: 20, scale: 8, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.decimal "locked_amount", precision: 20, scale: 8, default: "0.0", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "asset_code"], name: "index_balances_on_account_and_asset", unique: true
    t.index ["account_id"], name: "index_balances_on_account_id"
  end

  create_table "ledger_entries", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.decimal "amount", precision: 20, scale: 8, null: false
    t.string "asset_code", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "side", null: false
    t.uuid "transaction_id", null: false
    t.index ["account_id", "asset_code"], name: "index_ledger_entries_on_account_id_and_asset_code"
    t.index ["created_at"], name: "index_ledger_entries_on_created_at"
    t.check_constraint "amount > 0::numeric", name: "ledger_entries_amount_positive_check"
    t.check_constraint "side::text = ANY (ARRAY['debit'::character varying, 'credit'::character varying]::text[])", name: "ledger_entries_side_check"
  end

  create_table "ledger_transactions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "reference_id", null: false
    t.string "reference_type", null: false
    t.datetime "updated_at", null: false
    t.index ["reference_type", "reference_id"], name: "index_ledger_transactions_on_reference", unique: true
  end

  add_foreign_key "balances", "accounts"
  add_foreign_key "ledger_entries", "accounts"
  add_foreign_key "ledger_entries", "ledger_transactions", column: "transaction_id"
end
