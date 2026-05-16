# 01 System Context Adapter

## Goal
Position `banking-admin` in the system as the canonical Rails adapter for banking domain APIs.

## Key Points
- Accepts upstream client or gateway requests for banking routes.
- Delegates domain behavior to `banking-core` use cases.
- Persists via adapter implementations and Rails-backed DB runtime.

## Extensibility Boundary
Transport callers can vary if they preserve API contract and correlation header semantics.

## Diagram Source
- `DIAGRAM.mmd`
