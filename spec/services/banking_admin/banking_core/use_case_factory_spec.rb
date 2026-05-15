require "rails_helper"

RSpec.describe BankingAdmin::BankingCore::UseCaseFactory do
  it "builds all configured use cases" do
    factory = described_class.new

    expect(factory.create_account).to be_a(::BankingCore::UseCases::CreateAccount)
    expect(factory.post_ledger_transaction).to be_a(::BankingCore::UseCases::PostLedgerTransaction)
    expect(factory.project_balances_from_ledger).to be_a(::BankingCore::UseCases::ProjectBalancesFromLedger)
  end
end
