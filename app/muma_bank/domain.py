"""Banking domain models and exceptions."""

from __future__ import annotations

from dataclasses import dataclass
from decimal import Decimal


class BankingError(Exception):
    """Base class for expected banking errors."""


class AccountNotFoundError(BankingError):
    """Raised when an account identifier does not exist."""


class InvalidTransferError(BankingError):
    """Raised when transfer input violates business rules."""


class InsufficientFundsError(BankingError):
    """Raised when an account cannot fund a transfer."""


@dataclass(slots=True)
class Account:
    """An account with a decimal-safe balance."""

    account_id: str
    owner: str
    balance: Decimal
    currency: str = "INR"

    def to_dict(self) -> dict[str, str]:
        """Return a JSON-safe account representation."""
        return {
            "account_id": self.account_id,
            "owner": self.owner,
            "balance": f"{self.balance:.2f}",
            "currency": self.currency,
        }
