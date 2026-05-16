module BankingAdmin
  module Events
    class OutboxPublisherJob < ApplicationJob
      queue_as :default

      def perform
        OutboxPublisher.new.call
      end
    end
  end
end
