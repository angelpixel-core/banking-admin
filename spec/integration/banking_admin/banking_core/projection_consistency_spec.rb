require "rails_helper"
require "securerandom"

RSpec.describe "T6 balance projection consistency" do
  before do
    allow(BankingAdmin::Observability::Logger).to receive(:info)

    @service = BankingAdmin::BankingCore::LedgerService.new
    @debit_account_id = SecureRandom.uuid
    @credit_account_id = SecureRandom.uuid

    @service.create_account(id: @debit_account_id, account_type: "user", base_currency: "usd")
    @service.create_account(id: @credit_account_id, account_type: "user", base_currency: "usd")
  end

  it "projects balances asynchronously via job" do
    create_balanced_transaction(reference_id: "t6-async-1")

    expect(BankingAdmin::Persistence::BalanceRecord.count).to eq(0)

    BankingAdmin::BankingCore::ProjectBalancesJob.perform_now

    debit_balance = BankingAdmin::Persistence::BalanceRecord.find_by(account_id: @debit_account_id, asset_code: "USD")
    credit_balance = BankingAdmin::Persistence::BalanceRecord.find_by(account_id: @credit_account_id, asset_code: "USD")

    expect(debit_balance.available_amount).to eq(BigDecimal("100.0"))
    expect(credit_balance.available_amount).to eq(BigDecimal("-100.0"))
    expect(BankingAdmin::Observability::Logger).to have_received(:info).with(
      hash_including(event: "projection.job.completed", status: "completed")
    )
  end

  it "returns no drift when projection matches ledger history" do
    create_balanced_transaction(reference_id: "t6-consistency-1")
    @service.project_balances

    drifts = BankingAdmin::BankingCore::ProjectionConsistencyVerifier.new.call
    expect(drifts).to be_empty
  end

  it "returns drift rows when balances diverge" do
    create_balanced_transaction(reference_id: "t6-consistency-2")
    @service.project_balances

    balance = BankingAdmin::Persistence::BalanceRecord.find_by(account_id: @debit_account_id, asset_code: "USD")
    balance.update!(available_amount: BigDecimal("999.0"))

    drifts = BankingAdmin::BankingCore::ProjectionConsistencyVerifier.new.call
    expect(drifts).not_to be_empty

    drift = drifts.find { |row| row.account_id == @debit_account_id && row.asset_code == "USD" }
    expect(drift).not_to be_nil
    expect(drift.expected).to eq(BigDecimal("100.0"))
    expect(drift.actual).to eq(BigDecimal("999.0"))
  end

  def create_balanced_transaction(reference_id:)
    @service.post_transaction(
      reference_type: "transfer",
      reference_id: reference_id,
      entries: [
        build_entry(account_id: @debit_account_id, side: "debit", amount: "100.00", reference_id: reference_id),
        build_entry(account_id: @credit_account_id, side: "credit", amount: "100.00", reference_id: reference_id)
      ]
    )
  end

  def build_entry(account_id:, side:, amount:, reference_id:)
    ::BankingCore::Entities::LedgerEntry.new(
      id: SecureRandom.uuid,
      account_id: account_id,
      side: side,
      money: ::BankingCore::ValueObjects::Money.new(amount: amount, asset_code: "USD"),
      reference_type: "transfer",
      reference_id: reference_id
    )
  end
end
