module BankingAdmin
  module BankingCore
    class ProjectionConsistencyVerifier
      Drift = Struct.new(:account_id, :asset_code, :expected, :actual, keyword_init: true)

      def call
        expected = expected_projection
        actual = actual_projection
        keys = (expected.keys + actual.keys).uniq

        keys.filter_map do |key|
          expected_amount = expected.fetch(key, BigDecimal("0"))
          actual_amount = actual.fetch(key, BigDecimal("0"))
          next if expected_amount == actual_amount

          Drift.new(
            account_id: key[0],
            asset_code: key[1],
            expected: expected_amount,
            actual: actual_amount
          )
        end
      end

      private

      def expected_projection
        projection = Hash.new { |h, k| h[k] = BigDecimal("0") }

        BankingAdmin::Persistence::LedgerEntryRecord.find_each do |entry|
          key = [entry.account_id, entry.asset_code]
          signed_amount = entry.side == "debit" ? entry.amount : -entry.amount
          projection[key] += signed_amount
        end

        projection
      end

      def actual_projection
        projection = {}

        BankingAdmin::Persistence::BalanceRecord.find_each do |balance|
          projection[[balance.account_id, balance.asset_code]] = balance.available_amount
        end

        projection
      end
    end
  end
end
