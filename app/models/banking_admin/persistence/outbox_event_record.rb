module BankingAdmin
  module Persistence
    class OutboxEventRecord < ApplicationRecord
      self.table_name = "outbox_events"

      scope :publishable, lambda {
        where(state: "pending").where("next_attempt_at IS NULL OR next_attempt_at <= ?", Time.current)
      }
    end
  end
end
