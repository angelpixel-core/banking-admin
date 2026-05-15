require "securerandom"

module BankingAdmin
  module Api
    module V1
      class LedgerEntriesController < BaseController
        def create
          payload = create_ledger_params
          transaction = ledger_service.post_transaction(
            reference_type: payload[:reference_type],
            reference_id: payload[:reference_id],
            entries: build_entries(payload[:entries] || [])
          )

          render json: {
            reference_type: transaction.reference_type,
            reference_id: transaction.reference_id,
            entry_count: transaction.entries.size,
            correlation_id: correlation_id
          }, status: :created
        end

        private

        def create_ledger_params
          params.require(:ledger_entry).permit(:reference_type, :reference_id, entries: %i[id account_id side asset_code amount])
        end

        def build_entries(entries)
          entries.map do |entry|
            ::BankingCore::Entities::LedgerEntry.new(
              id: entry[:id] || SecureRandom.uuid,
              account_id: entry[:account_id],
              side: entry[:side],
              money: ::BankingCore::ValueObjects::Money.new(amount: entry[:amount], asset_code: entry[:asset_code]),
              reference_type: create_ledger_params[:reference_type],
              reference_id: create_ledger_params[:reference_id]
            )
          end
        end

        def ledger_service
          @ledger_service ||= BankingAdmin::BankingCore::LedgerService.new
        end
      end
    end
  end
end
