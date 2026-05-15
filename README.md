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
