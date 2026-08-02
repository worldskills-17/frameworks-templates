# django

A minimal [Django](https://www.djangoproject.com/) project with optional SQL
database support, served by gunicorn on port 80.

- Settings: `config/settings.py`  ·  URLs: `config/urls.py`
- Health check: `GET /health`; DB status: `GET /db-status`
- Admin CLI: `python manage.py <command>`

## Database (optional)

Set by the platform via `DATABASE_URL` (`mysql://...` or `postgresql://...`),
parsed with `dj-database-url`. If unset, the app runs with no database. Drivers:
PostgreSQL (`psycopg`) and MySQL (`PyMySQL`, installed as MySQLdb).

## Packages

`pip install` reads `PIP_INDEX_URL` (the offline PyPI mirror during the
competition). Add dependencies to `requirements.txt`.
