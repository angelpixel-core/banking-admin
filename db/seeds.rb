debit_account_id = "11111111-1111-1111-1111-111111111111"
credit_account_id = "22222222-2222-2222-2222-222222222222"
reference_type = "seed_transfer"
reference_id = "seed-ref-0001"

service = BankingAdmin::BankingCore::LedgerService.new

service.create_account(
  id: debit_account_id,
  account_type: "user",
  base_currency: "usd"
)

service.create_account(
  id: credit_account_id,
  account_type: "user",
  base_currency: "usd"
)

unless BankingAdmin::Persistence::LedgerTransactionRecord.exists?(reference_type: reference_type, reference_id: reference_id)
  service.post_transaction(
    reference_type: reference_type,
    reference_id: reference_id,
    entries: [
      BankingCore::Entities::LedgerEntry.new(
        id: "33333333-3333-3333-3333-333333333331",
        account_id: debit_account_id,
        side: "debit",
        money: BankingCore::ValueObjects::Money.new(amount: "100.00", asset_code: "USD"),
        reference_type: reference_type,
        reference_id: reference_id
      ),
      BankingCore::Entities::LedgerEntry.new(
        id: "33333333-3333-3333-3333-333333333332",
        account_id: credit_account_id,
        side: "credit",
        money: BankingCore::ValueObjects::Money.new(amount: "100.00", asset_code: "USD"),
        reference_type: reference_type,
        reference_id: reference_id
      )
    ]
  )
end

service.project_balances

puts "Seeded Banking Admin T2 dataset"
