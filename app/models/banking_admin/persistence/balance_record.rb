module BankingAdmin
  module Persistence
    class BalanceRecord < ApplicationRecord
      self.table_name = "balances"

      belongs_to :account_record,
                 class_name: "BankingAdmin::Persistence::AccountRecord",
                 foreign_key: :account_id,
                 inverse_of: :balance_records
    end
  end
end
