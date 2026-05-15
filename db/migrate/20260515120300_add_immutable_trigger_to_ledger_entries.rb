class AddImmutableTriggerToLedgerEntries < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
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

  def down
    execute <<~SQL
      DROP TRIGGER IF EXISTS trg_ledger_entries_no_update ON ledger_entries;
      DROP TRIGGER IF EXISTS trg_ledger_entries_no_delete ON ledger_entries;
      DROP FUNCTION IF EXISTS raise_ledger_entries_immutable();
    SQL
  end
end
