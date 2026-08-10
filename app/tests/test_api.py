"""API behavior tests."""

from decimal import Decimal

import pytest
from muma_bank import create_app
from muma_bank.domain import Account, InvalidTransferError
from muma_bank.repository import AccountRepository


def test_dashboard_renders(client):
    response = client.get("/")
    assert response.status_code == 200
    assert b"Muma Bank" in response.data
    assert b"Your money" in response.data
    assert b"transfer-form" in response.data


def test_dashboard_assets_are_available(client):
    assert client.get("/static/styles.css").status_code == 200
    assert client.get("/static/app.js").status_code == 200


def test_readiness_reports_unavailable_repository():
    class UnavailableRepository(AccountRepository):
        def is_ready(self) -> bool:
            return False

    app = create_app({"TESTING": True}, repository=UnavailableRepository.with_demo_data())
    response = app.test_client().get("/readyz")
    assert response.status_code == 503
    assert response.get_json()["status"] == "not_ready"


def test_health_and_readiness(client):
    assert client.get("/healthz").get_json() == {"service": "muma-bank", "status": "ok"}
    assert client.get("/readyz").get_json() == {
        "checks": {"repository": True},
        "status": "ready",
    }


def test_response_contains_supplied_request_id(client):
    response = client.get("/healthz", headers={"X-Request-ID": "request-123"})
    assert response.headers["X-Request-ID"] == "request-123"


def test_lists_seeded_accounts(client):
    response = client.get("/api/v1/accounts")
    assert response.status_code == 200
    assert response.get_json()["count"] == 3


def test_gets_account(client):
    response = client.get("/api/v1/accounts/ACC-1001")
    assert response.status_code == 200
    assert response.get_json()["account"]["balance"] == "25000.00"


def test_missing_account_returns_json_error(client):
    response = client.get("/api/v1/accounts/unknown")
    assert response.status_code == 404
    assert response.get_json()["error"]["code"] == "account_not_found"


def test_transfer_moves_decimal_amount(client):
    response = client.post(
        "/api/v1/transfers",
        json={
            "source_account_id": "ACC-1001",
            "destination_account_id": "ACC-1002",
            "amount": "125.50",
        },
    )
    body = response.get_json()["transfer"]
    assert response.status_code == 201
    assert body["source"]["balance"] == "24874.50"
    assert body["destination"]["balance"] == "18125.50"


def test_transfer_rejects_insufficient_funds(client):
    response = client.post(
        "/api/v1/transfers",
        json={
            "source_account_id": "ACC-1003",
            "destination_account_id": "ACC-1002",
            "amount": "9000.00",
        },
    )
    assert response.status_code == 409
    assert response.get_json()["error"]["code"] == "insufficient_funds"


@pytest.mark.parametrize(
    "payload,message",
    [
        ({}, "identifiers are required"),
        (
            {"source_account_id": "ACC-1001", "destination_account_id": "ACC-1002"},
            "valid number",
        ),
        (
            {
                "source_account_id": "ACC-1001",
                "destination_account_id": "ACC-1002",
                "amount": "1.001",
            },
            "two decimal places",
        ),
        (
            {
                "source_account_id": "ACC-1001",
                "destination_account_id": "ACC-1001",
                "amount": "1.00",
            },
            "must differ",
        ),
    ],
)
def test_transfer_validation(client, payload, message):
    response = client.post("/api/v1/transfers", json=payload)
    assert response.status_code == 400
    assert message in response.get_json()["error"]["message"]


def test_repository_rejects_currency_mismatch():
    repository = AccountRepository(
        [
            Account("INR-1", "One", Decimal("10.00"), "INR"),
            Account("USD-1", "Two", Decimal("10.00"), "USD"),
        ]
    )
    with pytest.raises(InvalidTransferError, match="currencies must match"):
        repository.transfer("INR-1", "USD-1", Decimal("1.00"))
