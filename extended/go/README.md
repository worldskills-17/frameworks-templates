# go (gin)

A [Gin](https://gin-gonic.com/) web application with optional SQL database
support. Dependencies are vendored (`vendor/`) so the image builds fully offline
- no Go module proxy or mirror is required.

- Entry point: `main.go`
- Listens on port 80 (override with `PORT`)
- Health check: `GET /health`; DB status: `GET /db-status`

## Database (optional)

Set by the platform via `DATABASE_URL` (`mysql://...` or `postgresql://...`).
If unset, the app runs without a database. Drivers vendored: MySQL
(`go-sql-driver/mysql`) and PostgreSQL (`lib/pq`).

To add a dependency: `go get <pkg>` then `go mod vendor`, and commit `vendor/`.
