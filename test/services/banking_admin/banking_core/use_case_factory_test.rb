require "test_helper"

class BankingAdmin::BankingCore::UseCaseFactoryTest < ActiveSupport::TestCase
  test "builds all configured use cases" do
    factory = BankingAdmin::BankingCore::UseCaseFactory.new

    assert_instance_of ::BankingCore::UseCases::CreateAccount, factory.create_account
    assert_instance_of ::BankingCore::UseCases::PostLedgerTransaction, factory.post_ledger_transaction
    assert_instance_of ::BankingCore::UseCases::ProjectBalancesFromLedger, factory.project_balances_from_ledger
  end
end
