"""PostgreSQL repository unit tests with isolated database doubles."""

from decimal import Decimal
from unittest.mock import MagicMock

import psycopg
import pytest
from muma_bank.database import PostgresAccountRepository
from muma_bank.domain import (
    AccountNotFoundError,
    InsufficientFundsError,
    InvalidTransferError,
)


def database_double(monkeypatch, *, fetchone=None, fetchall=None):
    connection_context = MagicMock()
    connection = connection_context.__enter__.return_value
    cursor_context = connection.cursor.return_value
    cursor = cursor_context.__enter__.return_value
    cursor.fetchone.return_value = fetchone
    cursor.fetchall.return_value = fetchall or []
    repository = PostgresAccountRepository("postgresql://test")
    monkeypatch.setattr(repository, "_connect", lambda: connection_context)
    return repository, cursor


def row(account_id, balance="100.00", currency="INR"):
    return {
        "account_id": account_id,
        "owner": f"Owner {account_id}",
        "balance": Decimal(balance),
        "currency": currency,
    }


def test_initialize_creates_and_seeds_empty_database(monkeypatch):
    repository, cursor = database_double(monkeypatch, fetchone={"count": 0})
    repository.initialize()
    assert cursor.execute.call_count == 3
    cursor.executemany.assert_called_once()


def test_initialize_does_not_replace_existing_data(monkeypatch):
    repository, cursor = database_double(monkeypatch, fetchone={"count": 3})
    repository.initialize()
    cursor.executemany.assert_not_called()


def test_readiness_reports_database_state(monkeypatch):
    repository, _ = database_double(monkeypatch, fetchone={"result": 1})
    assert repository.is_ready() is True
    monkeypatch.setattr(
        repository,
        "_connect",
        MagicMock(side_effect=psycopg.OperationalError("unavailable")),
    )
    assert repository.is_ready() is False


def test_lists_and_gets_accounts(monkeypatch):
    repository, cursor = database_double(monkeypatch, fetchall=[row("ACC-1")])
    assert repository.list_accounts()[0].account_id == "ACC-1"
    cursor.fetchone.return_value = row("ACC-2")
    assert repository.get_account("ACC-2").balance == Decimal("100.00")


def test_get_missing_account_raises(monkeypatch):
    repository, _ = database_double(monkeypatch)
    with pytest.raises(AccountNotFoundError):
        repository.get_account("missing")


def test_transfer_updates_both_locked_accounts(monkeypatch):
    repository, cursor = database_double(
        monkeypatch,
        fetchall=[row("ACC-1"), row("ACC-2", "50.00")],
    )
    result = repository.transfer("ACC-1", "ACC-2", Decimal("25.00"))
    assert result["source"]["balance"] == "75.00"
    assert result["destination"]["balance"] == "75.00"
    assert cursor.execute.call_count == 3


@pytest.mark.parametrize(
    "source,destination,amount,rows,error",
    [
        ("ACC-1", "ACC-1", Decimal("1.00"), [], InvalidTransferError),
        ("ACC-1", "ACC-2", Decimal("0.00"), [], InvalidTransferError),
        ("ACC-1", "ACC-2", Decimal("1.00"), [row("ACC-1")], AccountNotFoundError),
        (
            "ACC-1",
            "ACC-2",
            Decimal("1.00"),
            [row("ACC-1"), row("ACC-2", currency="USD")],
            InvalidTransferError,
        ),
        (
            "ACC-1",
            "ACC-2",
            Decimal("101.00"),
            [row("ACC-1"), row("ACC-2")],
            InsufficientFundsError,
        ),
    ],
)
def test_transfer_rejects_invalid_operations(
    monkeypatch, source, destination, amount, rows, error
):
    repository, _ = database_double(monkeypatch, fetchall=rows)
    with pytest.raises(error):
        repository.transfer(source, destination, amount)
