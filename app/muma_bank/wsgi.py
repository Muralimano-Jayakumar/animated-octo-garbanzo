"""WSGI entry point for local and production-style servers."""

from muma_bank import create_app

app = create_app()
