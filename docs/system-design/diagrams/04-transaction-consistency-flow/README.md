# 04 Transaction Consistency Flow

## Goal
Explain write-path consistency from request ingestion to committed ledger transaction.

## Key Points
- Controller validates contract-level shape.
- Core enforces aggregate invariants.
- Adapter unit of work defines transaction boundary and commit.
- Projection update follows committed ledger truth.

## Extensibility Boundary
Alternative persistence engines can be used if atomicity and invariant guarantees are preserved.

## Diagram Source
- `DIAGRAM.mmd`
