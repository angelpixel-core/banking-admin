# 07 Extensibility Boundary

## Goal
Map stable extension points for new capabilities without breaking core ownership boundaries.

## Key Points
- New API routes should compose existing service and use-case factories.
- New storage runtime should implement repository and unit-of-work interfaces.
- New event integration should be emitted after committed domain writes.

## Extensibility Boundary
Core domain rules cannot be bypassed by extension paths.

## Diagram Source
- `DIAGRAM.mmd`
