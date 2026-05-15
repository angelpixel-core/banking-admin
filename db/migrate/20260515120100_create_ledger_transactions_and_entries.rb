class CreateLedgerTransactionsAndEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :ledger_transactions, id: :uuid do |t|
      t.string :reference_type, null: false
      t.string :reference_id, null: false

      t.timestamps
    end

    add_index :ledger_transactions, %i[reference_type reference_id], unique: true, name: "index_ledger_transactions_on_reference"

    create_table :ledger_entries, id: :uuid do |t|
      t.uuid :transaction_id, null: false
      t.uuid :account_id, null: false
      t.string :side, null: false
      t.string :asset_code, null: false
      t.decimal :amount, precision: 20, scale: 8, null: false
      t.datetime :created_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
    end

    add_foreign_key :ledger_entries, :ledger_transactions, column: :transaction_id
    add_foreign_key :ledger_entries, :accounts, column: :account_id
    add_index :ledger_entries, %i[account_id asset_code]
    add_index :ledger_entries, :created_at
    add_check_constraint :ledger_entries, "side IN ('debit', 'credit')", name: "ledger_entries_side_check"
    add_check_constraint :ledger_entries, "amount > 0", name: "ledger_entries_amount_positive_check"
  end
end
