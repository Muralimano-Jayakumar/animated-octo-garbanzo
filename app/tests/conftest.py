"""Shared Flask test fixtures."""

import pytest
from muma_bank import create_app


@pytest.fixture
def app():
    return create_app({"TESTING": True})


@pytest.fixture
def client(app):
    return app.test_client()
