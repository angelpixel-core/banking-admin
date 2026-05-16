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

  desc "Rebuild balances projection from ledger history"
  task rebuild_balances: :environment do
    started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    projected = BankingAdmin::BankingCore::LedgerService.new.project_balances
    elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at

    puts "projected_balances=#{projected}"
    puts format("elapsed_seconds=%.3f", elapsed)
    puts "rebuild_balances OK"
  end

  desc "Verify balances projection consistency against ledger history"
  task verify_projection_consistency: :environment do
    drifts = BankingAdmin::BankingCore::ProjectionConsistencyVerifier.new.call

    if drifts.empty?
      puts "projection_consistency OK"
      next
    end

    puts "projection_consistency FAILED drift_count=#{drifts.size}"
    drifts.each do |drift|
      puts(
        "account_id=#{drift.account_id} asset_code=#{drift.asset_code} expected=#{drift.expected.to_s('F')} actual=#{drift.actual.to_s('F')}"
      )
    end

    abort "Projection drift detected"
  end
end
