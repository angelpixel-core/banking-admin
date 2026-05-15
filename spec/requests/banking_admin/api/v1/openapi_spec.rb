require "swagger_helper"

RSpec.describe "BankingAdmin API V1", type: :request do
  path "/banking_admin/api/v1/accounts" do
    post "Create account" do
      tags "Accounts"
      consumes "application/json"
      produces "application/json"
      parameter name: "X-Correlation-ID", in: :header, schema: { type: :string }
      parameter name: :account, in: :body, schema: { "$ref" => "#/components/schemas/account_create_request" }

      response "201", "account created" do
        schema "$ref" => "#/components/schemas/account_create_response"
        let(:"X-Correlation-ID") { "openapi-account-1" }
        let(:account) { { account: json_fixture("accounts/create_valid") } }

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body["correlation_id"]).to eq("openapi-account-1")
        end
      end

      response "422", "invalid account state" do
        schema "$ref" => "#/components/schemas/error_envelope"
        let(:"X-Correlation-ID") { "openapi-account-2" }
        let(:account) { { account: json_fixture("accounts/create_invalid_type") } }

        run_test!
      end
    end
  end

  path "/banking_admin/api/v1/ledger_entries" do
    post "Post ledger entries" do
      tags "Ledger"
      consumes "application/json"
      produces "application/json"
      parameter name: "X-Correlation-ID", in: :header, schema: { type: :string }
      parameter name: :ledger_entry, in: :body, schema: { "$ref" => "#/components/schemas/ledger_entries_create_request" }

      before do
        service = BankingAdmin::BankingCore::LedgerService.new
        service.create_account(id: "11111111-1111-1111-1111-111111111111", account_type: "user", base_currency: "usd")
        service.create_account(id: "22222222-2222-2222-2222-222222222222", account_type: "user", base_currency: "usd")
      end

      response "201", "ledger transaction created" do
        schema "$ref" => "#/components/schemas/ledger_entries_create_response"
        let(:"X-Correlation-ID") { "openapi-ledger-1" }
        let(:ledger_entry) { { ledger_entry: json_fixture("ledger_entries/post_valid") } }

        run_test!
      end

      response "409", "duplicate reference" do
        schema "$ref" => "#/components/schemas/error_envelope"
        let(:"X-Correlation-ID") { "openapi-ledger-2" }
        let(:ledger_entry) { { ledger_entry: json_fixture("ledger_entries/post_duplicate_reference") } }

        before do
          post "/banking_admin/api/v1/ledger_entries", params: ledger_entry, as: :json
        end

        run_test!
      end

      response "422", "unbalanced transaction" do
        schema "$ref" => "#/components/schemas/error_envelope"
        let(:"X-Correlation-ID") { "openapi-ledger-3" }
        let(:ledger_entry) { { ledger_entry: json_fixture("ledger_entries/post_unbalanced") } }

        run_test!
      end
    end
  end

  path "/banking_admin/api/v1/balances" do
    get "List balances" do
      tags "Balances"
      produces "application/json"
      parameter name: "X-Correlation-ID", in: :header, schema: { type: :string }
      parameter name: :account_id, in: :query, schema: { type: :string, format: :uuid }
      parameter name: :asset_code, in: :query, schema: { type: :string }

      before do
        service = BankingAdmin::BankingCore::LedgerService.new
        debit_account_id = "11111111-1111-1111-1111-111111111111"
        credit_account_id = "22222222-2222-2222-2222-222222222222"
        service.create_account(id: debit_account_id, account_type: "user", base_currency: "usd")
        service.create_account(id: credit_account_id, account_type: "user", base_currency: "usd")

        entries = [
          ::BankingCore::Entities::LedgerEntry.new(
            id: SecureRandom.uuid,
            account_id: debit_account_id,
            side: "debit",
            money: ::BankingCore::ValueObjects::Money.new(amount: "100.00", asset_code: "USD"),
            reference_type: "transfer",
            reference_id: "openapi-balance-ref-1"
          ),
          ::BankingCore::Entities::LedgerEntry.new(
            id: SecureRandom.uuid,
            account_id: credit_account_id,
            side: "credit",
            money: ::BankingCore::ValueObjects::Money.new(amount: "100.00", asset_code: "USD"),
            reference_type: "transfer",
            reference_id: "openapi-balance-ref-1"
          )
        ]
        service.post_transaction(reference_type: "transfer", reference_id: "openapi-balance-ref-1", entries: entries)
        service.project_balances
      end

      response "200", "balances returned" do
        schema "$ref" => "#/components/schemas/balances_index_response"
        let(:"X-Correlation-ID") { "openapi-balance-1" }
        let(:account_id) { json_fixture("balances/get_by_account_query")["account_id"] }
        let(:asset_code) { json_fixture("balances/get_by_account_query")["asset_code"] }

        run_test!
      end
    end
  end
end
