module BankingAdmin
  module Events
    class EventBusPublisher
      def publish(_event)
        raise NotImplementedError, "configure a concrete event bus publisher"
      end
    end
  end
end
