# Banking Admin System Design

Tags: `banking-admin`, `system-design`, `rails-adapter`, `api-contracts`, `immutability`

## Purpose

Describe `apps/banking-admin` as the official Rails adapter for `packages/banking-core`, with deep internal architecture and abstract integration boundaries.

## Scope

- API surface and contract ownership.
- Adapter composition around framework-agnostic core use cases.
- Persistence model and immutability reinforcement.
- Error and correlation propagation model.
- CI and operational readiness topology.

## Non-Scope

- Replacing domain ownership from `banking-core`.
- Cross-service orchestration owned by gateway or other apps.

## Diagram Index

Each folder contains:
- `README.md` with interview-style explanation
- `DIAGRAM.mmd` with canonical Mermaid source

1. `diagrams/01-system-context-adapter/`
2. `diagrams/02-adapter-internal-architecture/`
3. `diagrams/03-api-contract-ownership/`
4. `diagrams/04-transaction-consistency-flow/`
5. `diagrams/05-error-correlation-flow/`
6. `diagrams/06-persistence-and-immutability-model/`
7. `diagrams/07-extensibility-boundary/`
8. `diagrams/08-testing-and-ci-topology/`
9. `diagrams/09-operational-readiness-flow/`

## Design Principles

- `banking-core` remains framework agnostic and domain owner.
- `banking-admin` owns adapter concerns: transport, persistence wiring, and process boundaries.
- Financial invariants are enforced in core and reinforced at DB level.
- Integration points are modeled as contracts to keep future adapters possible.

## References

- `apps/banking-admin/README.md`
- `packages/banking-core/README.md`
- `docs/05-service-boundary.md`
- `docs/07-api-contracts.md`
- `docs/10-security-model.md`
- `docs/12-observability-strategy.md`
