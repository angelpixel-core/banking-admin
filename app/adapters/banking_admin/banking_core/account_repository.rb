module BankingAdmin
  module BankingCore
    class AccountRepository
      def save(account)
        record = Persistence::AccountRecord.find_or_initialize_by(id: account.id)
        record.account_type = account.account_type
        record.status = account.status
        record.base_currency = account.base_currency
        record.created_at = account.created_at
        record.updated_at = Time.current
        record.save!
      end

      def find(account_id)
        record = Persistence::AccountRecord.find_by(id: account_id)
        return nil unless record

        ::BankingCore::Entities::Account.new(
          id: record.id,
          account_type: record.account_type,
          status: record.status,
          base_currency: record.base_currency,
          created_at: record.created_at
        )
      end
    end
  end
end
