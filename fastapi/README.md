# fastapi

A [FastAPI](https://fastapi.tiangolo.com/) app with optional SQL database
support, served by uvicorn on port 80.

- Entry point: `app/main.py`
- Health check: `GET /health`; DB status: `GET /db-status`

## Database (optional)

Set by the platform via `DATABASE_URL` (`mysql://...` or `postgresql://...`).
If unset, the app runs without a database. Drivers: PostgreSQL (`psycopg`) and
MySQL (`PyMySQL`), connected through SQLAlchemy.

## Packages

`pip install` reads `PIP_INDEX_URL` (the offline PyPI mirror during the
competition). Add dependencies to `requirements.txt`.
