module BankingAdmin
  module BankingCore
    class ProjectBalancesJob < ApplicationJob
      queue_as :default

      def perform
        LedgerService.new.project_balances
      end
    end
  end
end
