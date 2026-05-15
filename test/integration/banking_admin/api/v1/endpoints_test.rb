require "test_helper"

class BankingAdmin::API::V1::EndpointsTest < ActionDispatch::IntegrationTest
  setup do
    @service = BankingAdmin::BankingCore::LedgerService.new
    @debit_account_id = "11111111-1111-1111-1111-111111111111"
    @credit_account_id = "22222222-2222-2222-2222-222222222222"

    @service.create_account(id: @debit_account_id, account_type: "user", base_currency: "usd")
    @service.create_account(id: @credit_account_id, account_type: "user", base_currency: "usd")
  end

  test "POST /accounts creates account" do
    payload = json_fixture("accounts/create_valid")
    expected = json_fixture("accounts/create_valid_expected")

    post banking_admin_api_v1_accounts_path,
         params: { account: payload },
         as: :json,
         headers: { "X-Correlation-ID" => "test-corr-accounts-1" }

    assert_response :created
    body = JSON.parse(response.body)

    assert_equal expected["id"], body["id"]
    assert_equal expected["account_type"], body["account_type"]
    assert_equal expected["base_currency"], body["base_currency"]
    assert_equal expected["status"], body["status"]
    assert_equal "test-corr-accounts-1", body["correlation_id"]
  end

  test "POST /accounts returns structured error for invalid account type" do
    payload = json_fixture("accounts/create_invalid_type")

    post banking_admin_api_v1_accounts_path,
         params: { account: payload },
         as: :json,
         headers: { "X-Correlation-ID" => "test-corr-accounts-2" }

    assert_response :unprocessable_entity
    body = JSON.parse(response.body)

    assert_equal "invalid_account_state", body["code"]
    assert_equal "invalid account_type", body["message"]
    assert_equal "test-corr-accounts-2", body["correlation_id"]
  end

  test "POST /ledger_entries creates ledger transaction" do
    payload = json_fixture("ledger_entries/post_valid")
    expected = json_fixture("ledger_entries/post_valid_expected")

    post banking_admin_api_v1_ledger_entries_path,
         params: { ledger_entry: payload },
         as: :json,
         headers: { "X-Correlation-ID" => "test-corr-ledger-1" }

    assert_response :created
    body = JSON.parse(response.body)

    assert_equal expected["reference_type"], body["reference_type"]
    assert_equal expected["reference_id"], body["reference_id"]
    assert_equal expected["entry_count"], body["entry_count"]
    assert_equal "test-corr-ledger-1", body["correlation_id"]
  end

  test "POST /ledger_entries returns structured duplicate reference error" do
    payload = json_fixture("ledger_entries/post_duplicate_reference")

    post banking_admin_api_v1_ledger_entries_path,
         params: { ledger_entry: payload },
         as: :json,
         headers: { "X-Correlation-ID" => "test-corr-ledger-2" }
    assert_response :created

    post banking_admin_api_v1_ledger_entries_path,
         params: { ledger_entry: payload },
         as: :json,
         headers: { "X-Correlation-ID" => "test-corr-ledger-3" }

    assert_response :conflict
    body = JSON.parse(response.body)
    expected = json_fixture("errors/duplicate_reference_expected")

    assert_equal expected["code"], body["code"]
    assert_equal expected["message"], body["message"]
    assert_equal "test-corr-ledger-3", body["correlation_id"]
  end

  test "POST /ledger_entries returns structured unbalanced transaction error" do
    payload = json_fixture("ledger_entries/post_unbalanced")
    expected = json_fixture("errors/unbalanced_transaction_expected")

    post banking_admin_api_v1_ledger_entries_path,
         params: { ledger_entry: payload },
         as: :json,
         headers: { "X-Correlation-ID" => "test-corr-ledger-4" }

    assert_response :unprocessable_entity
    body = JSON.parse(response.body)

    assert_equal expected["code"], body["code"]
    assert_equal expected["message"], body["message"]
    assert_equal "test-corr-ledger-4", body["correlation_id"]
  end

  test "GET /balances filters by account and asset" do
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

    assert_response :ok
    body = JSON.parse(response.body)
    assert_equal "test-corr-balances-1", body["correlation_id"]
    assert_equal 1, body["balances"].size

    balance = body["balances"].first
    assert_equal expected_balance["account_id"], balance["account_id"]
    assert_equal expected_balance["asset_code"], balance["asset_code"]
    assert_equal expected_balance["available_amount"], balance["available_amount"]
    assert_equal expected_balance["locked_amount"], balance["locked_amount"]
    assert_equal expected_balance["borrowed_amount"], balance["borrowed_amount"]
  end

  private

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
