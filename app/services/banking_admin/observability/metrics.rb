module BankingAdmin
  module Observability
    class Metrics
      SERVICE_NAME = "banking-admin".freeze

      def self.increment(name:, value: 1, labels: {})
        emit(type: "counter", name: name, value: value, labels: labels)
      end

      def self.observe(name:, value:, labels: {})
        emit(type: "histogram", name: name, value: value, labels: labels)
      end

      def self.set(name:, value:, labels: {})
        emit(type: "gauge", name: name, value: value, labels: labels)
      end

      def self.emit(type:, name:, value:, labels: {})
        Rails.logger.info(
          {
            service: SERVICE_NAME,
            event: "metric.#{type}",
            metric_name: name,
            value: value,
            labels: labels,
            timestamp: Time.current.utc.iso8601
          }.to_json
        )
      end
      private_class_method :emit
    end
  end
end
