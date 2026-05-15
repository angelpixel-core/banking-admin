module BankingAdmin
  module Persistence
    class LedgerTransactionRecord < ApplicationRecord
      self.table_name = "ledger_transactions"

      has_many :ledger_entry_records,
               class_name: "BankingAdmin::Persistence::LedgerEntryRecord",
               foreign_key: :transaction_id,
               inverse_of: :ledger_transaction_record,
               dependent: :restrict_with_exception
    end
  end
end
