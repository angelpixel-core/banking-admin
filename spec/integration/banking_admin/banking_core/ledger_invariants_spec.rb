require "rails_helper"
require "securerandom"

RSpec.describe "BankingCore ledger invariants" do
  before do
    ensure_ledger_entries_immutable_trigger!

    @service = BankingAdmin::BankingCore::LedgerService.new
    @debit_account_id = SecureRandom.uuid
    @credit_account_id = SecureRandom.uuid

    @service.create_account(id: @debit_account_id, account_type: "user", base_currency: "usd")
    @service.create_account(id: @credit_account_id, account_type: "user", base_currency: "usd")
  end

  it "posts balanced transaction successfully" do
    transaction = @service.post_transaction(
      reference_type: "transfer",
      reference_id: "ref-balanced-1",
      entries: balanced_entries("ref-balanced-1")
    )

    expect(transaction.reference_key).to eq("transfer:ref-balanced-1")
    expect(BankingAdmin::Persistence::LedgerTransactionRecord.count).to eq(1)
    expect(BankingAdmin::Persistence::LedgerEntryRecord.count).to eq(2)
  end

  it "rejects duplicate transaction reference" do
    @service.post_transaction(
      reference_type: "transfer",
      reference_id: "ref-dup-1",
      entries: balanced_entries("ref-dup-1")
    )

    expect do
      @service.post_transaction(
        reference_type: "transfer",
        reference_id: "ref-dup-1",
        entries: balanced_entries("ref-dup-1")
      )
    end.to raise_error(::BankingCore::DuplicateLedgerReferenceError)
  end

  it "rejects unbalanced transaction" do
    expect do
      @service.post_transaction(
        reference_type: "transfer",
        reference_id: "ref-unbalanced-1",
        entries: [
          build_entry(account_id: @debit_account_id, side: "debit", amount: "100.00", reference_id: "ref-unbalanced-1"),
          build_entry(account_id: @credit_account_id, side: "credit", amount: "90.00", reference_id: "ref-unbalanced-1")
        ]
      )
    end.to raise_error(::BankingCore::UnbalancedLedgerTransactionError)
  end

  it "installs immutable SQL trigger for ledger entries" do
    @service.post_transaction(
      reference_type: "transfer",
      reference_id: "ref-immutable-1",
      entries: balanced_entries("ref-immutable-1")
    )

    entry = BankingAdmin::Persistence::LedgerEntryRecord.first
    expect(entry).not_to be_nil
    expect(BankingAdmin::Persistence::LedgerEntryRecord.count).to be > 0

    trigger_count = ActiveRecord::Base.connection.select_value(<<~SQL)
      SELECT COUNT(*)
      FROM pg_trigger
      WHERE tgname IN ('trg_ledger_entries_no_update', 'trg_ledger_entries_no_delete')
    SQL

    expect(trigger_count.to_i).to eq(2)
  end

  it "projects balances from ledger history" do
    @service.post_transaction(
      reference_type: "transfer",
      reference_id: "ref-project-1",
      entries: balanced_entries("ref-project-1")
    )

    projected_count = @service.project_balances
    expect(projected_count).to eq(2)

    debit_balance = BankingAdmin::Persistence::BalanceRecord.find_by(account_id: @debit_account_id, asset_code: "USD")
    credit_balance = BankingAdmin::Persistence::BalanceRecord.find_by(account_id: @credit_account_id, asset_code: "USD")

    expect(debit_balance.available_amount).to eq(BigDecimal("100.0"))
    expect(credit_balance.available_amount).to eq(BigDecimal("-100.0"))
  end

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
