"""fastapi: a FastAPI app with optional SQL database support.

Database is optional and driven by the DATABASE_URL environment variable injected
by the platform (mysql://... or postgresql://...?sslmode=disable). If unset, the
app runs without a database.
"""
import os

from fastapi import FastAPI
from fastapi.responses import HTMLResponse, PlainTextResponse

app = FastAPI()


def _engine_url():
    """Return (sqlalchemy_url, engine_name). engine_name is 'none' when unset."""
    raw = os.getenv("DATABASE_URL", "").strip()
    if not raw:
        return None, "none"
    if raw.startswith("postgresql://") or raw.startswith("postgres://"):
        url = raw.replace("postgresql://", "postgresql+psycopg://", 1)
        url = url.replace("postgres://", "postgresql+psycopg://", 1)
        return url, "postgres"
    if raw.startswith("mysql://"):
        # SQLAlchemy needs a driver dialect; PyMySQL is pure-python.
        return raw.replace("mysql://", "mysql+pymysql://", 1), "mysql"
    return None, "unsupported"


@app.get("/health", response_class=PlainTextResponse)
def health():
    return "ok"


@app.get("/", response_class=HTMLResponse)
def index():
    _, engine = _engine_url()
    return f"""<!doctype html>
<html lang="en"><head><meta charset="utf-8"><title>fastapi</title>
<style>body{{font-family:system-ui;margin:3rem auto;max-width:40rem;line-height:1.6}}</style></head>
<body><h1>fastapi</h1><p>FastAPI app is running. Database engine: <code>{engine}</code>.</p>
<p>Edit <code>app/main.py</code> to build your solution. See <code>/db-status</code>.</p></body></html>"""


@app.get("/db-status")
def db_status():
    url, engine = _engine_url()
    if not url:
        return {"database": engine, "connected": False}
    try:
        from sqlalchemy import create_engine, text
        eng = create_engine(url, pool_pre_ping=True)
        with eng.connect() as conn:
            conn.execute(text("SELECT 1"))
        return {"database": engine, "connected": True}
    except Exception as exc:  # never crash the endpoint on a DB error
        return {"database": engine, "connected": False, "error": str(exc)}
