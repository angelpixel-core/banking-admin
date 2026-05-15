module BankingAdmin
  module Api
    module V1
      class BalancesController < BaseController
        def index
          balances = BankingAdmin::Persistence::BalanceRecord.all
          balances = balances.where(account_id: params[:account_id]) if params[:account_id].present?
          balances = balances.where(asset_code: params[:asset_code]) if params[:asset_code].present?

          render json: {
            balances: balances.map { |balance| serialize_balance(balance) },
            correlation_id: correlation_id
          }, status: :ok
        end

        private

        def serialize_balance(balance)
          {
            account_id: balance.account_id,
            asset_code: balance.asset_code,
            available_amount: balance.available_amount.to_s,
            locked_amount: balance.locked_amount.to_s,
            borrowed_amount: balance.borrowed_amount.to_s
          }
        end
      end
    end
  end
end
