# 06 Persistence and Immutability Model

## Goal
Describe table-level roles and immutability reinforcement strategy.

## Key Points
- `ledger_entries` and `ledger_transactions` model canonical write history.
- `balances` remains projection read model.
- SQL trigger prevents update/delete on ledger entries.

## Extensibility Boundary
Schema implementations can evolve if immutable ledger semantics and reference uniqueness remain enforced.

## Diagram Source
- `DIAGRAM.mmd`
