# 05 Error Correlation Flow

## Goal
Show error envelope ownership and correlation propagation across adapter layers.

## Key Points
- Correlation ID enters through request header or is generated.
- Errors are mapped to structured envelope with code/message/correlation_id.
- Correlation is included in success and failure responses.

## Extensibility Boundary
Error source can vary by downstream implementation; response envelope contract remains stable.

## Diagram Source
- `DIAGRAM.mmd`
