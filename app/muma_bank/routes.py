"""HTTP routes for health checks and banking operations."""

from __future__ import annotations

from decimal import Decimal, InvalidOperation
from typing import cast
from uuid import uuid4

from flask import Blueprint, current_app, jsonify, render_template, request

from muma_bank.domain import InvalidTransferError
from muma_bank.repository import AccountStore

api = Blueprint("api", __name__)


def _repository() -> AccountStore:
    return cast(AccountStore, current_app.extensions["account_repository"])


@api.get("/")
def index():
    """Render the banking dashboard."""
    return render_template("index.html")


@api.before_app_request
def assign_request_id() -> None:
    """Use a supplied correlation ID or generate one."""
    request.request_id = request.headers.get("X-Request-ID") or str(uuid4())


@api.after_app_request
def include_request_id(response):
    """Expose the correlation ID on every response."""
    response.headers["X-Request-ID"] = request.request_id
    return response


@api.get("/healthz")
def health():
    return jsonify({"service": current_app.config["SERVICE_NAME"], "status": "ok"})


@api.get("/readyz")
def readiness():
    ready = _repository().is_ready()
    body = {"checks": {"repository": ready}, "status": "ready" if ready else "not_ready"}
    return jsonify(body), 200 if ready else 503


@api.get("/api/v1/accounts")
def list_accounts():
    accounts = [account.to_dict() for account in _repository().list_accounts()]
    return jsonify({"accounts": accounts, "count": len(accounts)})


@api.get("/api/v1/accounts/<account_id>")
def get_account(account_id: str):
    return jsonify({"account": _repository().get_account(account_id).to_dict()})


@api.post("/api/v1/transfers")
def create_transfer():
    payload = request.get_json(silent=True)
    if not isinstance(payload, dict):
        raise InvalidTransferError("Request body must be a JSON object")

    source_id = payload.get("source_account_id")
    destination_id = payload.get("destination_account_id")
    raw_amount = payload.get("amount")
    if not isinstance(source_id, str) or not isinstance(destination_id, str):
        raise InvalidTransferError("Source and destination account identifiers are required")

    try:
        amount = Decimal(str(raw_amount))
    except (InvalidOperation, ValueError):
        raise InvalidTransferError("Transfer amount must be a valid number") from None

    if not amount.is_finite() or amount.as_tuple().exponent < -2:
        raise InvalidTransferError("Transfer amount must have at most two decimal places")

    result = _repository().transfer(source_id, destination_id, amount)
    current_app.extensions["application_metrics"].transfers.inc()
    return jsonify({"transfer": result}), 201
