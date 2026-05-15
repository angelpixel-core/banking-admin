module BankingAdmin
  module API
    class BaseController < ActionController::API
      before_action :assign_correlation_id
      after_action :set_correlation_header

      rescue_from ActionController::ParameterMissing do |error|
        render_error(code: "invalid_request", message: error.message, status: :bad_request)
      end

      rescue_from ::BankingCore::DuplicateLedgerReferenceError do |error|
        render_error(code: "duplicate_reference", message: error.message, status: :conflict)
      end

      rescue_from ::BankingCore::UnbalancedLedgerTransactionError do |error|
        render_error(code: "unbalanced_transaction", message: error.message, status: :unprocessable_entity)
      end

      rescue_from ::BankingCore::InvalidAccountStateError do |error|
        render_error(code: "invalid_account_state", message: error.message, status: :unprocessable_entity)
      end

      rescue_from ArgumentError do |error|
        render_error(code: "invalid_argument", message: error.message, status: :bad_request)
      end

      private

      attr_reader :correlation_id

      def assign_correlation_id
        @correlation_id = request.headers["X-Correlation-ID"].presence || request.request_id
      end

      def set_correlation_header
        response.set_header("X-Correlation-ID", correlation_id)
      end

      def render_error(code:, message:, status:, details: nil)
        payload = {
          code: code,
          message: message,
          correlation_id: correlation_id
        }
        payload[:details] = details if details

        render json: payload, status: status
      end
    end
  end
end
