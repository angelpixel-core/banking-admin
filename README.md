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
