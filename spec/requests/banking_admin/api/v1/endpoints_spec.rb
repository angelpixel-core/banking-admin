require "rails_helper"

RSpec.describe "BankingAdmin API V1 endpoints" do
  before do
    allow(BankingAdmin::Observability::Logger).to receive(:info)

    @service = BankingAdmin::BankingCore::LedgerService.new
    @debit_account_id = "11111111-1111-1111-1111-111111111111"
    @credit_account_id = "22222222-2222-2222-2222-222222222222"

    @service.create_account(id: @debit_account_id, account_type: "user", base_currency: "usd")
    @service.create_account(id: @credit_account_id, account_type: "user", base_currency: "usd")
  end

  it "creates account" do
    payload = json_fixture("accounts/create_valid")
    expected = json_fixture("accounts/create_valid_expected")

    post banking_admin_api_v1_accounts_path,
         params: { account: payload },
         as: :json,
         headers: { "X-Correlation-ID" => "test-corr-accounts-1" }

    expect(response).to have_http_status(:created)
    body = JSON.parse(response.body)

    expect(body["id"]).to eq(expected["id"])
    expect(body["account_type"]).to eq(expected["account_type"])
    expect(body["base_currency"]).to eq(expected["base_currency"])
    expect(body["status"]).to eq(expected["status"])
    expect(body["correlation_id"]).to eq("test-corr-accounts-1")
  end

  it "returns structured error for invalid account type" do
    payload = json_fixture("accounts/create_invalid_type")

    post banking_admin_api_v1_accounts_path,
         params: { account: payload },
         as: :json,
         headers: { "X-Correlation-ID" => "test-corr-accounts-2" }

    expect(response).to have_http_status(:unprocessable_content)
    body = JSON.parse(response.body)

    expect(body["code"]).to eq("invalid_account_state")
    expect(body["message"]).to eq("invalid account_type")
    expect(body["correlation_id"]).to eq("test-corr-accounts-2")
  end

  it "creates ledger transaction" do
    payload = json_fixture("ledger_entries/post_valid")
    expected = json_fixture("ledger_entries/post_valid_expected")

    expect do
      post banking_admin_api_v1_ledger_entries_path,
           params: { ledger_entry: payload },
           as: :json,
           headers: { "X-Correlation-ID" => "test-corr-ledger-1" }
    end.to have_enqueued_job(BankingAdmin::BankingCore::ProjectBalancesJob)

    expect(response).to have_http_status(:created)
    body = JSON.parse(response.body)

    expect(body["reference_type"]).to eq(expected["reference_type"])
    expect(body["reference_id"]).to eq(expected["reference_id"])
    expect(body["entry_count"]).to eq(expected["entry_count"])
    expect(body["correlation_id"]).to eq("test-corr-ledger-1")

    outbox_event = BankingAdmin::Persistence::OutboxEventRecord.order(:created_at).last
    expect(outbox_event).not_to be_nil
    expect(outbox_event.event_name).to eq("ledger.entry.posted")
    expect(outbox_event.event_version).to eq("v1")
    expect(outbox_event.correlation_id).to eq("test-corr-ledger-1")
    expect(outbox_event.producer).to eq("banking-admin")
    expect(outbox_event.state).to eq("pending")
    expect(outbox_event.payload["reference_type"]).to eq(expected["reference_type"])
    expect(outbox_event.payload["reference_id"]).to eq(expected["reference_id"])
    expect(BankingAdmin::Observability::Logger).to have_received(:info).with(
      hash_including(event: "ledger.post.accepted", status: "accepted", correlation_id: "test-corr-ledger-1")
    )
  end

  it "returns structured duplicate reference error" do
    payload = json_fixture("ledger_entries/post_duplicate_reference")

    post banking_admin_api_v1_ledger_entries_path,
         params: { ledger_entry: payload },
         as: :json,
         headers: { "X-Correlation-ID" => "test-corr-ledger-2" }
    expect(response).to have_http_status(:created)
    expect(enqueued_jobs.size).to eq(1)

    post banking_admin_api_v1_ledger_entries_path,
         params: { ledger_entry: payload },
         as: :json,
         headers: { "X-Correlation-ID" => "test-corr-ledger-3" }

    expect(response).to have_http_status(:conflict)
    body = JSON.parse(response.body)
    expected = json_fixture("errors/duplicate_reference_expected")

    expect(body["code"]).to eq(expected["code"])
    expect(body["message"]).to eq(expected["message"])
    expect(body["correlation_id"]).to eq("test-corr-ledger-3")

    expect(BankingAdmin::Persistence::OutboxEventRecord.count).to eq(1)
    expect(enqueued_jobs.size).to eq(1)
  end

  it "returns structured unbalanced transaction error" do
    payload = json_fixture("ledger_entries/post_unbalanced")
    expected = json_fixture("errors/unbalanced_transaction_expected")

    post banking_admin_api_v1_ledger_entries_path,
         params: { ledger_entry: payload },
         as: :json,
         headers: { "X-Correlation-ID" => "test-corr-ledger-4" }

    expect(response).to have_http_status(:unprocessable_content)
    body = JSON.parse(response.body)

    expect(body["code"]).to eq(expected["code"])
    expect(body["message"]).to eq(expected["message"])
    expect(body["correlation_id"]).to eq("test-corr-ledger-4")

    expect(BankingAdmin::Persistence::OutboxEventRecord.count).to eq(0)
  end

  it "filters balances by account and asset" do
    @service.post_transaction(
      reference_type: "transfer",
      reference_id: "api-balance-ref-1",
      entries: [
        build_entry(account_id: @debit_account_id, side: "debit", amount: "100.00", reference_id: "api-balance-ref-1"),
        build_entry(account_id: @credit_account_id, side: "credit", amount: "100.00", reference_id: "api-balance-ref-1")
      ]
    )
    @service.project_balances

    query = json_fixture("balances/get_by_account_query")
    expected_balance = json_fixture("balances/get_by_account_expected")

    get banking_admin_api_v1_balances_path,
        params: query,
        as: :json,
        headers: { "X-Correlation-ID" => "test-corr-balances-1" }

    expect(response).to have_http_status(:ok)
    body = JSON.parse(response.body)
    expect(body["correlation_id"]).to eq("test-corr-balances-1")
    expect(body["balances"].size).to eq(1)

    balance = body["balances"].first
    expect(balance["account_id"]).to eq(expected_balance["account_id"])
    expect(balance["asset_code"]).to eq(expected_balance["asset_code"])
    expect(balance["available_amount"]).to eq(expected_balance["available_amount"])
    expect(balance["locked_amount"]).to eq(expected_balance["locked_amount"])
    expect(balance["borrowed_amount"]).to eq(expected_balance["borrowed_amount"])
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
