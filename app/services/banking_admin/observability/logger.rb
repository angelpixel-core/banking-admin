module BankingAdmin
  module Observability
    class Logger
      SERVICE_NAME = "banking-admin".freeze

      def self.info(event:, status:, correlation_id:, reference_type: nil, reference_id: nil, duration_ms: nil, error_code: nil)
        payload = {
          service: SERVICE_NAME,
          event: event,
          status: status,
          correlation_id: correlation_id,
          reference_type: reference_type,
          reference_id: reference_id,
          duration_ms: duration_ms,
          error_code: error_code,
          timestamp: Time.current.utc.iso8601
        }.compact

        Rails.logger.info(payload.to_json)
      end
    end
  end
end
