class CreateBalances < ActiveRecord::Migration[8.1]
  def change
    create_table :balances, id: :uuid do |t|
      t.uuid :account_id, null: false
      t.string :asset_code, null: false
      t.decimal :available_amount, precision: 20, scale: 8, null: false, default: 0
      t.decimal :locked_amount, precision: 20, scale: 8, null: false, default: 0
      t.decimal :borrowed_amount, precision: 20, scale: 8, null: false, default: 0

      t.timestamps
    end

    add_foreign_key :balances, :accounts, column: :account_id
    add_index :balances, :account_id
    add_index :balances, %i[account_id asset_code], unique: true, name: "index_balances_on_account_and_asset"
  end
end
