# 08 Testing and CI Topology

## Goal
Describe how test layers and CI jobs validate adapter correctness.

## Key Points
- Request specs validate API behavior and envelopes.
- Integration specs validate domain-facing workflows.
- OpenAPI generation validates contract shape.
- System scaffold keeps CI path stable.

## Extensibility Boundary
New features must add tests at the appropriate layer without weakening existing contract checks.

## Diagram Source
- `DIAGRAM.mmd`
