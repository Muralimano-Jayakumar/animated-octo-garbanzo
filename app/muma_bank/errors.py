"""HTTP error mapping for the banking API."""

from __future__ import annotations

from flask import Flask, jsonify, request
from werkzeug.exceptions import HTTPException

from muma_bank.domain import (
    AccountNotFoundError,
    InsufficientFundsError,
    InvalidTransferError,
)


def _error_response(code: str, message: str, status: int):
    return (
        jsonify(
            {
                "error": {"code": code, "message": message},
                "request_id": getattr(request, "request_id", None),
            }
        ),
        status,
    )


def register_error_handlers(app: Flask) -> None:
    """Register consistent JSON error responses."""

    @app.errorhandler(AccountNotFoundError)
    def account_not_found(error: AccountNotFoundError):
        return _error_response("account_not_found", str(error), 404)

    @app.errorhandler(InvalidTransferError)
    def invalid_transfer(error: InvalidTransferError):
        return _error_response("invalid_transfer", str(error), 400)

    @app.errorhandler(InsufficientFundsError)
    def insufficient_funds(error: InsufficientFundsError):
        return _error_response("insufficient_funds", str(error), 409)

    @app.errorhandler(HTTPException)
    def http_error(error: HTTPException):
        return _error_response("http_error", error.description, error.code or 500)
