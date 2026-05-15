module BankingAdmin
  module BankingCore
    class LedgerService
      def initialize(factory: UseCaseFactory.new)
        @create_account = factory.create_account
        @post_ledger_transaction = factory.post_ledger_transaction
        @project_balances_from_ledger = factory.project_balances_from_ledger
      end

      def create_account(**args)
        @create_account.call(**args)
      end

      def post_transaction(**args)
        @post_ledger_transaction.call(**args)
      end

      def project_balances
        @project_balances_from_ledger.call
      end
    end
  end
end
