# vanilla-go

A dependency-free Go web application using only the standard library
(`net/http`). Builds fully offline - no module proxy or package mirror required.

- Entry point: `main.go`
- Listens on port 80 (override with the `PORT` environment variable)
- Health check: `GET /health`

Add your handlers in `main.go`. To use external Go modules, switch to the `go`
template (which vendors its dependencies), or commit a `vendor/` directory.
