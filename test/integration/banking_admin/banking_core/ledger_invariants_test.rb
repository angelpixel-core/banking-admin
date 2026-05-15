require "test_helper"
require "securerandom"

class BankingAdmin::BankingCore::LedgerInvariantsTest < ActiveSupport::TestCase
  setup do
    @service = BankingAdmin::BankingCore::LedgerService.new
    @debit_account_id = SecureRandom.uuid
    @credit_account_id = SecureRandom.uuid

    @service.create_account(id: @debit_account_id, account_type: "user", base_currency: "usd")
    @service.create_account(id: @credit_account_id, account_type: "user", base_currency: "usd")
  end

  test "posts balanced transaction successfully" do
    transaction = @service.post_transaction(
      reference_type: "transfer",
      reference_id: "ref-balanced-1",
      entries: balanced_entries("ref-balanced-1")
    )

    assert_equal "transfer:ref-balanced-1", transaction.reference_key
    assert_equal 1, BankingAdmin::Persistence::LedgerTransactionRecord.count
    assert_equal 2, BankingAdmin::Persistence::LedgerEntryRecord.count
  end

  test "rejects duplicate transaction reference" do
    @service.post_transaction(
      reference_type: "transfer",
      reference_id: "ref-dup-1",
      entries: balanced_entries("ref-dup-1")
    )

    assert_raises(BankingCore::DuplicateLedgerReferenceError) do
      @service.post_transaction(
        reference_type: "transfer",
        reference_id: "ref-dup-1",
        entries: balanced_entries("ref-dup-1")
      )
    end
  end

  test "rejects unbalanced transaction" do
    assert_raises(BankingCore::UnbalancedLedgerTransactionError) do
      @service.post_transaction(
        reference_type: "transfer",
        reference_id: "ref-unbalanced-1",
        entries: [
          build_entry(account_id: @debit_account_id, side: "debit", amount: "100.00", reference_id: "ref-unbalanced-1"),
          build_entry(account_id: @credit_account_id, side: "credit", amount: "90.00", reference_id: "ref-unbalanced-1")
        ]
      )
    end
  end

  test "prevents updates and deletes on ledger entries via SQL trigger" do
    @service.post_transaction(
      reference_type: "transfer",
      reference_id: "ref-immutable-1",
      entries: balanced_entries("ref-immutable-1")
    )

    entry = BankingAdmin::Persistence::LedgerEntryRecord.first

    error = assert_raises(ActiveRecord::StatementInvalid) do
      entry.update!(amount: 123.45)
    end
    assert_includes error.message, "ledger_entries are immutable"

    error = assert_raises(ActiveRecord::StatementInvalid) do
      entry.destroy!
    end
    assert_includes error.message, "ledger_entries are immutable"
  end

  test "projects balances from ledger history" do
    @service.post_transaction(
      reference_type: "transfer",
      reference_id: "ref-project-1",
      entries: balanced_entries("ref-project-1")
    )

    projected_count = @service.project_balances

    assert_equal 2, projected_count
    debit_balance = BankingAdmin::Persistence::BalanceRecord.find_by(account_id: @debit_account_id, asset_code: "USD")
    credit_balance = BankingAdmin::Persistence::BalanceRecord.find_by(account_id: @credit_account_id, asset_code: "USD")

    assert_equal BigDecimal("100.0"), debit_balance.available_amount
    assert_equal BigDecimal("-100.0"), credit_balance.available_amount
  end

  private

  def balanced_entries(reference_id)
    [
      build_entry(account_id: @debit_account_id, side: "debit", amount: "100.00", reference_id: reference_id),
      build_entry(account_id: @credit_account_id, side: "credit", amount: "100.00", reference_id: reference_id)
    ]
  end

  def build_entry(account_id:, side:, amount:, reference_id:)
    BankingCore::Entities::LedgerEntry.new(
      id: SecureRandom.uuid,
      account_id: account_id,
      side: side,
      money: BankingCore::ValueObjects::Money.new(amount: amount, asset_code: "USD"),
      reference_type: "transfer",
      reference_id: reference_id
    )
  end
end
