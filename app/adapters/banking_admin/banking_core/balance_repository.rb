module BankingAdmin
  module BankingCore
    class BalanceRepository
      def find(account_id, asset_code)
        record = ::BankingAdmin::Persistence::BalanceRecord.find_by(account_id: account_id, asset_code: asset_code)
        return nil unless record

        to_entity(record)
      end

      def save(balance)
        record = ::BankingAdmin::Persistence::BalanceRecord.find_or_initialize_by(
          account_id: balance.account_id,
          asset_code: balance.asset_code
        )
        record.id ||= SecureRandom.uuid
        record.available_amount = balance.available_amount
        record.locked_amount = balance.locked_amount
        record.borrowed_amount = balance.borrowed_amount
        record.save!
      end

      private

      def to_entity(record)
        ::BankingCore::Entities::Balance.new(
          account_id: record.account_id,
          asset_code: record.asset_code,
          available_amount: record.available_amount,
          locked_amount: record.locked_amount,
          borrowed_amount: record.borrowed_amount
        )
      end
    end
  end
end
