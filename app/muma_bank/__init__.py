"""Muma Bank Flask application factory."""

from __future__ import annotations

from collections.abc import Mapping
from typing import Any

from flask import Flask

from muma_bank.errors import register_error_handlers
from muma_bank.repository import AccountRepository
from muma_bank.routes import api


def create_app(
    config: Mapping[str, Any] | None = None,
    repository: AccountRepository | None = None,
) -> Flask:
    """Create and configure the Flask application."""
    app = Flask(__name__)
    app.config.from_mapping(
        SERVICE_NAME="muma-bank",
        JSON_SORT_KEYS=False,
    )

    if config:
        app.config.from_mapping(config)

    app.extensions["account_repository"] = repository or AccountRepository.with_demo_data()
    app.register_blueprint(api)
    register_error_handlers(app)
    return app
