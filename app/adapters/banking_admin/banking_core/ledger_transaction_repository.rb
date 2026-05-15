module BankingAdmin
  module BankingCore
    class LedgerTransactionRepository
      def exists_reference?(reference_type, reference_id)
        Persistence::LedgerTransactionRecord.exists?(reference_type: reference_type, reference_id: reference_id)
      end

      def save(transaction)
        transaction_record = Persistence::LedgerTransactionRecord.create!(
          id: SecureRandom.uuid,
          reference_type: transaction.reference_type,
          reference_id: transaction.reference_id,
          created_at: transaction.created_at,
          updated_at: transaction.created_at
        )

        transaction.entries.each do |entry|
          Persistence::LedgerEntryRecord.create!(
            id: entry.id,
            transaction_id: transaction_record.id,
            account_id: entry.account_id,
            side: entry.side,
            asset_code: entry.asset_code,
            amount: entry.amount,
            created_at: entry.created_at
          )
        end
      end

      def all_entries
        Persistence::LedgerEntryRecord.order(:created_at).map do |record|
          ::BankingCore::Entities::LedgerEntry.new(
            id: record.id,
            account_id: record.account_id,
            side: record.side,
            money: ::BankingCore::ValueObjects::Money.new(amount: record.amount, asset_code: record.asset_code),
            reference_type: record.ledger_transaction_record.reference_type,
            reference_id: record.ledger_transaction_record.reference_id,
            created_at: record.created_at
          )
        end
      end
    end
  end
end
