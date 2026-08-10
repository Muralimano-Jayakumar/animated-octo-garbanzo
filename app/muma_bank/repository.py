"""Thread-safe in-memory account repository."""

from __future__ import annotations

from decimal import Decimal
from threading import RLock
from typing import Protocol

from muma_bank.domain import (
    Account,
    AccountNotFoundError,
    InsufficientFundsError,
    InvalidTransferError,
)


class AccountStore(Protocol):
    """Repository contract used by HTTP routes."""

    def is_ready(self) -> bool: ...

    def list_accounts(self) -> list[Account]: ...

    def get_account(self, account_id: str) -> Account: ...

    def transfer(
        self, source_id: str, destination_id: str, amount: Decimal
    ) -> dict[str, object]: ...


class AccountRepository:
    """Store accounts and execute atomic in-process transfers."""

    def __init__(self, accounts: list[Account] | None = None) -> None:
        self._accounts = {account.account_id: account for account in accounts or []}
        self._lock = RLock()

    @classmethod
    def with_demo_data(cls) -> AccountRepository:
        """Create a repository with deterministic demo accounts."""
        return cls(
            [
                Account("ACC-1001", "Aarav Sharma", Decimal("25000.00")),
                Account("ACC-1002", "Diya Patel", Decimal("18000.00")),
                Account("ACC-1003", "Kabir Singh", Decimal("7500.00")),
            ]
        )

    def is_ready(self) -> bool:
        """Report whether the repository is available to serve requests."""
        return True

    def list_accounts(self) -> list[Account]:
        """Return accounts ordered by identifier."""
        with self._lock:
            return [self._accounts[key] for key in sorted(self._accounts)]

    def get_account(self, account_id: str) -> Account:
        """Return one account or raise a domain error."""
        with self._lock:
            try:
                return self._accounts[account_id]
            except KeyError as exc:
                raise AccountNotFoundError(f"Account '{account_id}' was not found") from exc

    def transfer(self, source_id: str, destination_id: str, amount: Decimal) -> dict[str, object]:
        """Atomically transfer funds between two accounts."""
        if source_id == destination_id:
            raise InvalidTransferError("Source and destination accounts must differ")
        if amount <= Decimal("0.00"):
            raise InvalidTransferError("Transfer amount must be greater than zero")

        with self._lock:
            source = self.get_account(source_id)
            destination = self.get_account(destination_id)

            if source.currency != destination.currency:
                raise InvalidTransferError("Account currencies must match")
            if source.balance < amount:
                raise InsufficientFundsError("Source account has insufficient funds")

            source.balance -= amount
            destination.balance += amount

            return {
                "amount": f"{amount:.2f}",
                "currency": source.currency,
                "source": source.to_dict(),
                "destination": destination.to_dict(),
            }
