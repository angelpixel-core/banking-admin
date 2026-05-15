module BankingAdmin
  module BankingCore
    class UseCaseFactory
      def initialize
        @account_repository = AccountRepository.new
        @ledger_transaction_repository = LedgerTransactionRepository.new
        @balance_repository = BalanceRepository.new
        @unit_of_work = UnitOfWork.new
      end

      def create_account
        ::BankingCore::UseCases::CreateAccount.new(
          account_repository: @account_repository,
          unit_of_work: @unit_of_work
        )
      end

      def post_ledger_transaction
        ::BankingCore::UseCases::PostLedgerTransaction.new(
          ledger_transaction_repository: @ledger_transaction_repository,
          unit_of_work: @unit_of_work
        )
      end

      def project_balances_from_ledger
        ::BankingCore::UseCases::ProjectBalancesFromLedger.new(
          ledger_transaction_repository: @ledger_transaction_repository,
          balance_repository: @balance_repository,
          unit_of_work: @unit_of_work
        )
      end
    end
  end
end
