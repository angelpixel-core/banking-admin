# 03 API Contract Ownership

## Goal
Clarify which layer owns external API contracts and versioning guarantees.

## Key Points
- `banking-admin` owns `/banking_admin/api/v1/*` contract surfaces.
- OpenAPI is generated from request specs and component schemas.
- Domain semantics come from core use cases but response envelopes are adapter-owned.

## Extensibility Boundary
Version evolution should happen with explicit contract versioning, not silent response changes.

## Diagram Source
- `DIAGRAM.mmd`
