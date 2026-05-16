# 02 Adapter Internal Architecture

## Goal
Show internal module composition and responsibilities within the Rails adapter.

## Key Points
- Controllers handle HTTP and schema boundaries.
- Service/factory layers compose `banking-core` use cases.
- Repositories and UoW implement persistence ports.

## Extensibility Boundary
New routes should compose existing factory and port abstractions rather than bypassing core contracts.

## Diagram Source
- `DIAGRAM.mmd`
