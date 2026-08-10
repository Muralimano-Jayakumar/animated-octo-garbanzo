"""PostgreSQL-backed account repository."""

from __future__ import annotations

from decimal import Decimal

import psycopg
from psycopg.rows import dict_row

from muma_bank.domain import (
    Account,
    AccountNotFoundError,
    InsufficientFundsError,
    InvalidTransferError,
)


class PostgresAccountRepository:
    """Persist accounts and transactional transfers in PostgreSQL."""

    def __init__(self, database_url: str) -> None:
        self._database_url = database_url

    def _connect(self):
        return psycopg.connect(self._database_url, connect_timeout=3, row_factory=dict_row)

    def initialize(self) -> None:
        """Create the account schema and seed it only when empty."""
        with self._connect() as connection, connection.cursor() as cursor:
            cursor.execute(
                """
                CREATE TABLE IF NOT EXISTS accounts (
                    account_id TEXT PRIMARY KEY,
                    owner TEXT NOT NULL,
                    balance NUMERIC(18, 2) NOT NULL CHECK (balance >= 0),
                    currency VARCHAR(3) NOT NULL
                )
                """
            )
            cursor.execute("LOCK TABLE accounts IN SHARE ROW EXCLUSIVE MODE")
            cursor.execute("SELECT COUNT(*) AS count FROM accounts")
            if cursor.fetchone()["count"] == 0:
                cursor.executemany(
                    """
                    INSERT INTO accounts (account_id, owner, balance, currency)
                    VALUES (%s, %s, %s, %s)
                    """,
                    [
                        ("ACC-1001", "Aarav Sharma", Decimal("25000.00"), "INR"),
                        ("ACC-1002", "Diya Patel", Decimal("18000.00"), "INR"),
                        ("ACC-1003", "Kabir Singh", Decimal("7500.00"), "INR"),
                    ],
                )

    def is_ready(self) -> bool:
        """Return whether the database accepts a simple query."""
        try:
            with self._connect() as connection, connection.cursor() as cursor:
                cursor.execute("SELECT 1")
                return cursor.fetchone() is not None
        except psycopg.Error:
            return False

    @staticmethod
    def _to_account(row: dict[str, object]) -> Account:
        return Account(
            account_id=str(row["account_id"]),
            owner=str(row["owner"]),
            balance=Decimal(row["balance"]),
            currency=str(row["currency"]),
        )

    def list_accounts(self) -> list[Account]:
        """Return all persisted accounts ordered by identifier."""
        with self._connect() as connection, connection.cursor() as cursor:
            cursor.execute(
                "SELECT account_id, owner, balance, currency FROM accounts ORDER BY account_id"
            )
            return [self._to_account(row) for row in cursor.fetchall()]

    def get_account(self, account_id: str) -> Account:
        """Return one persisted account or raise a domain error."""
        with self._connect() as connection, connection.cursor() as cursor:
            cursor.execute(
                """
                SELECT account_id, owner, balance, currency
                FROM accounts
                WHERE account_id = %s
                """,
                (account_id,),
            )
            row = cursor.fetchone()

        if row is None:
            raise AccountNotFoundError(f"Account '{account_id}' was not found")
        return self._to_account(row)

    def transfer(
        self, source_id: str, destination_id: str, amount: Decimal
    ) -> dict[str, object]:
        """Move funds atomically while locking both account rows."""
        if source_id == destination_id:
            raise InvalidTransferError("Source and destination accounts must differ")
        if amount <= Decimal("0.00"):
            raise InvalidTransferError("Transfer amount must be greater than zero")

        with self._connect() as connection, connection.cursor() as cursor:
            cursor.execute(
                """
                SELECT account_id, owner, balance, currency
                FROM accounts
                WHERE account_id = ANY(%s)
                ORDER BY account_id
                FOR UPDATE
                """,
                ([source_id, destination_id],),
            )
            accounts = {row["account_id"]: self._to_account(row) for row in cursor.fetchall()}

            for account_id in (source_id, destination_id):
                if account_id not in accounts:
                    raise AccountNotFoundError(f"Account '{account_id}' was not found")

            source = accounts[source_id]
            destination = accounts[destination_id]
            if source.currency != destination.currency:
                raise InvalidTransferError("Account currencies must match")
            if source.balance < amount:
                raise InsufficientFundsError("Source account has insufficient funds")

            cursor.execute(
                "UPDATE accounts SET balance = balance - %s WHERE account_id = %s",
                (amount, source_id),
            )
            cursor.execute(
                "UPDATE accounts SET balance = balance + %s WHERE account_id = %s",
                (amount, destination_id),
            )
            source.balance -= amount
            destination.balance += amount

        return {
            "amount": f"{amount:.2f}",
            "currency": source.currency,
            "source": source.to_dict(),
            "destination": destination.to_dict(),
        }
