require "test_helper"
require "securerandom"

class BankingAdmin::BankingCore::LedgerInvariantsTest < ActiveSupport::TestCase
  setup do
    ensure_ledger_entries_immutable_trigger!

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

    assert_raises(::BankingCore::DuplicateLedgerReferenceError) do
      @service.post_transaction(
        reference_type: "transfer",
        reference_id: "ref-dup-1",
        entries: balanced_entries("ref-dup-1")
      )
    end
  end

  test "rejects unbalanced transaction" do
    assert_raises(::BankingCore::UnbalancedLedgerTransactionError) do
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

  test "installs immutable SQL trigger for ledger entries" do
    @service.post_transaction(
      reference_type: "transfer",
      reference_id: "ref-immutable-1",
      entries: balanced_entries("ref-immutable-1")
    )

    entry = BankingAdmin::Persistence::LedgerEntryRecord.first
    assert_not_nil entry
    assert_operator BankingAdmin::Persistence::LedgerEntryRecord.count, :>, 0

    trigger_count = ActiveRecord::Base.connection.select_value(<<~SQL)
      SELECT COUNT(*)
      FROM pg_trigger
      WHERE tgname IN ('trg_ledger_entries_no_update', 'trg_ledger_entries_no_delete')
    SQL
    assert_equal 2, trigger_count.to_i
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

  def ensure_ledger_entries_immutable_trigger!
    ActiveRecord::Base.connection.execute(<<~SQL)
      CREATE OR REPLACE FUNCTION raise_ledger_entries_immutable()
      RETURNS trigger AS $$
      BEGIN
        RAISE EXCEPTION 'ledger_entries are immutable';
      END;
      $$ LANGUAGE plpgsql;

      DROP TRIGGER IF EXISTS trg_ledger_entries_no_update ON ledger_entries;
      CREATE TRIGGER trg_ledger_entries_no_update
      BEFORE UPDATE ON ledger_entries
      FOR EACH ROW
      EXECUTE FUNCTION raise_ledger_entries_immutable();

      DROP TRIGGER IF EXISTS trg_ledger_entries_no_delete ON ledger_entries;
      CREATE TRIGGER trg_ledger_entries_no_delete
      BEFORE DELETE ON ledger_entries
      FOR EACH ROW
      EXECUTE FUNCTION raise_ledger_entries_immutable();
    SQL
  end

  def balanced_entries(reference_id)
    [
      build_entry(account_id: @debit_account_id, side: "debit", amount: "100.00", reference_id: reference_id),
      build_entry(account_id: @credit_account_id, side: "credit", amount: "100.00", reference_id: reference_id)
    ]
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
