module BankingAdmin
  module Persistence
    class LedgerEntryRecord < ApplicationRecord
      self.table_name = "ledger_entries"

      belongs_to :ledger_transaction_record,
                 class_name: "BankingAdmin::Persistence::LedgerTransactionRecord",
                 foreign_key: :transaction_id,
                 inverse_of: :ledger_entry_records
      belongs_to :account_record,
                 class_name: "BankingAdmin::Persistence::AccountRecord",
                 foreign_key: :account_id,
                 inverse_of: :ledger_entry_records
    end
  end
end
