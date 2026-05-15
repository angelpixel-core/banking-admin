# Banking Admin

Rails adapter app for FinOps Core Banking domain.

This app consumes the framework-agnostic `banking-core` package and provides:

- ActiveRecord persistence adapters,
- SQL/DB constraints and triggers,
- transaction boundaries and use case wiring.

## Architecture boundaries

- Domain logic and use cases live in `packages/banking-core`.
- Rails-specific persistence and composition live in this app under `BankingAdmin::...`.

## T2 persistence invariants

- Global idempotency: `ledger_transactions(reference_type, reference_id)` is unique.
- Immutable ledger entries: SQL trigger blocks update/delete on `ledger_entries`.
- Double-entry and domain checks are enforced by `banking-core` aggregate rules.

## Testing

Run the suite with:

```bash
bin/rails test
```

## Quick validation (local)

This app expects local Postgres from the project compose stack.

1. Start local platform from repo root:

```bash
make restart
```

2. Prepare Banking Admin database:

```bash
bin/rails db:prepare
```

3. Seed deterministic T2 dataset:

```bash
bin/rails banking_admin:seed_t2
```

4. Verify core invariants quickly:

```bash
bin/rails banking_admin:verify_t2
```

5. Run tests:

```bash
bin/rails test
```

## API payload fixtures for T3

Request and expected response payloads are tracked as JSON fixtures in:

- `test/fixtures/api_payloads/accounts/`
- `test/fixtures/api_payloads/ledger_entries/`
- `test/fixtures/api_payloads/balances/`
- `test/fixtures/api_payloads/errors/`

Use `json_fixture("path/without_extension")` in tests. Example:

```ruby
payload = json_fixture("ledger_entries/post_valid")
expected_error = json_fixture("errors/duplicate_reference_expected")
```

## API examples (T3)

Endpoints are exposed under `/banking_admin/api/v1`.

Create account:

```bash
curl -X POST http://localhost:3000/banking_admin/api/v1/accounts \
  -H "Content-Type: application/json" \
  -H "X-Correlation-ID: demo-account-1" \
  -d '{"account":{"id":"11111111-aaaa-bbbb-cccc-000000000001","account_type":"user","base_currency":"USD","status":"active"}}'
```

Post ledger entries:

```bash
curl -X POST http://localhost:3000/banking_admin/api/v1/ledger_entries \
  -H "Content-Type: application/json" \
  -H "X-Correlation-ID: demo-ledger-1" \
  -d '{"ledger_entry":{"reference_type":"transfer","reference_id":"demo-ref-0001","entries":[{"id":"33333333-3333-3333-3333-333333333331","account_id":"11111111-1111-1111-1111-111111111111","side":"debit","asset_code":"USD","amount":"100.00"},{"id":"33333333-3333-3333-3333-333333333332","account_id":"22222222-2222-2222-2222-222222222222","side":"credit","asset_code":"USD","amount":"100.00"}]}}'
```

Query balances:

```bash
curl "http://localhost:3000/banking_admin/api/v1/balances?account_id=11111111-1111-1111-1111-111111111111&asset_code=USD" \
  -H "X-Correlation-ID: demo-balance-1"
```
