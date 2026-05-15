module BankingAdmin
  module Persistence
    class AccountRecord < ApplicationRecord
      self.table_name = "accounts"

      has_many :ledger_entry_records,
               class_name: "BankingAdmin::Persistence::LedgerEntryRecord",
               foreign_key: :account_id,
               inverse_of: :account_record,
               dependent: :restrict_with_exception

      has_many :balance_records,
               class_name: "BankingAdmin::Persistence::BalanceRecord",
               foreign_key: :account_id,
               inverse_of: :account_record,
               dependent: :restrict_with_exception
    end
  end
end
