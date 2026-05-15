require "securerandom"

module BankingAdmin
  module API
    module V1
      class AccountsController < BaseController
        def create
          account = ledger_service.create_account(
            id: create_account_params[:id] || SecureRandom.uuid,
            account_type: create_account_params[:account_type],
            base_currency: create_account_params[:base_currency],
            status: create_account_params[:status] || "active"
          )

          render json: {
            id: account.id,
            account_type: account.account_type,
            base_currency: account.base_currency,
            status: account.status,
            correlation_id: correlation_id
          }, status: :created
        end

        private

        def create_account_params
          params.require(:account).permit(:id, :account_type, :base_currency, :status)
        end

        def ledger_service
          @ledger_service ||= BankingAdmin::BankingCore::LedgerService.new
        end
      end
    end
  end
end
