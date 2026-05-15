class CreateAccounts < ActiveRecord::Migration[8.1]
  def change
    create_table :accounts, id: :uuid do |t|
      t.string :account_type, null: false
      t.string :status, null: false
      t.string :base_currency, null: false

      t.timestamps
    end

    add_index :accounts, :status
    add_check_constraint :accounts, "account_type IN ('user', 'treasury', 'system')", name: "accounts_account_type_check"
    add_check_constraint :accounts, "status IN ('pending', 'active', 'suspended')", name: "accounts_status_check"
  end
end
