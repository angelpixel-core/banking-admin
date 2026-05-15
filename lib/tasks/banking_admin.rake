namespace :banking_admin do
  desc "Seed deterministic T2 dataset"
  task seed_t2: :environment do
    Rake::Task["db:seed"].invoke
  end

  desc "Verify T2 persistence invariants quickly"
  task verify_t2: :environment do
    accounts = BankingAdmin::Persistence::AccountRecord.count
    transactions = BankingAdmin::Persistence::LedgerTransactionRecord.count
    entries = BankingAdmin::Persistence::LedgerEntryRecord.count
    balances = BankingAdmin::Persistence::BalanceRecord.count

    trigger_count = ActiveRecord::Base.connection.select_value(<<~SQL).to_i
      SELECT COUNT(*)
      FROM pg_trigger
      WHERE tgname IN ('trg_ledger_entries_no_update', 'trg_ledger_entries_no_delete')
    SQL

    puts "accounts=#{accounts} transactions=#{transactions} entries=#{entries} balances=#{balances}"
    puts "immutable_triggers=#{trigger_count}"

    abort "Expected at least one account" if accounts.zero?
    abort "Expected at least one ledger transaction" if transactions.zero?
    abort "Expected at least two ledger entries" if entries < 2
    abort "Expected immutable triggers installed" unless trigger_count == 2

    puts "T2 verification OK"
  end
end
