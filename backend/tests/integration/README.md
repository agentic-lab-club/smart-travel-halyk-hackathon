# Integration Tests

This suite validates the end-to-end consumer journey:

- mobile-facing backend endpoints
- backend planning flow
- live backend-to-agent wiring via `/parse-trip`

Run through Docker Compose:

```bash
make integration-test-build
make integration-test
```

The suite expects:

- `postgres`
- `golang`
- `agent`

and runs Go tests with `-tags=integration`.
