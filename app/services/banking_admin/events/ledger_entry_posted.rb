module BankingAdmin
  module Events
    class LedgerEntryPosted
      def self.build_payload(transaction:, transaction_id:)
        {
          transaction_id: transaction_id,
          reference_type: transaction.reference_type,
          reference_id: transaction.reference_id,
          entry_count: transaction.entries.size,
          affected_accounts: transaction.entries.map(&:account_id).uniq,
          affected_assets: transaction.entries.map(&:asset_code).uniq
        }
      end
    end
  end
end
