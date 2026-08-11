"""Muma Bank Flask application factory."""

from __future__ import annotations

import os
from collections.abc import Mapping
from typing import Any

from flask import Flask

from muma_bank.database import PostgresAccountRepository
from muma_bank.errors import register_error_handlers
from muma_bank.metrics import ApplicationMetrics
from muma_bank.repository import AccountRepository, AccountStore
from muma_bank.routes import api


def create_app(
    config: Mapping[str, Any] | None = None,
    repository: AccountStore | None = None,
) -> Flask:
    """Create and configure the Flask application."""
    app = Flask(__name__)
    app.config.from_mapping(
        SERVICE_NAME="muma-bank",
        JSON_SORT_KEYS=False,
    )

    if config:
        app.config.from_mapping(config)

    if repository is None:
        database_url = os.getenv("DATABASE_URL")
        if database_url:
            postgres_repository = PostgresAccountRepository(database_url)
            postgres_repository.initialize()
            repository = postgres_repository
        else:
            repository = AccountRepository.with_demo_data()

    app.extensions["account_repository"] = repository
    ApplicationMetrics().init_app(app)
    app.register_blueprint(api)
    register_error_handlers(app)
    return app
