import os

from django.http import HttpResponse, JsonResponse
from django.urls import path


def _engine():
    url = os.getenv("DATABASE_URL", "")
    if url.startswith("postgres"):
        return "postgres"
    if url.startswith("mysql"):
        return "mysql"
    return "none"


def index(request):
    return HttpResponse(
        f"""<!doctype html>
<html lang="en"><head><meta charset="utf-8"><title>django</title>
<style>body{{font-family:system-ui;margin:3rem auto;max-width:40rem;line-height:1.6}}</style></head>
<body><h1>django</h1><p>Django app is running. Database engine: <code>{_engine()}</code>.</p>
<p>Edit <code>config/</code> and add apps to build your solution. See <code>/db-status</code>.</p></body></html>"""
    )


def health(request):
    return HttpResponse("ok", content_type="text/plain")


def db_status(request):
    # Drive off DATABASE_URL (Django injects a dummy default when DATABASES={}).
    if not os.getenv("DATABASE_URL", "").strip():
        return JsonResponse({"database": "none", "connected": False})
    from django.db import connections
    try:
        connections["default"].cursor().execute("SELECT 1")
        return JsonResponse({"database": _engine(), "connected": True})
    except Exception as exc:
        return JsonResponse({"database": _engine(), "connected": False, "error": str(exc)})


urlpatterns = [
    path("", index),
    path("health", health),
    path("db-status", db_status),
]
