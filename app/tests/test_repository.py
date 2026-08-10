"""Repository unit tests."""

from decimal import Decimal

import pytest
from muma_bank.domain import Account, AccountNotFoundError, InvalidTransferError
from muma_bank.repository import AccountRepository


def test_accounts_are_sorted():
    repository = AccountRepository(
        [
            Account("B", "Second", Decimal("2.00")),
            Account("A", "First", Decimal("1.00")),
        ]
    )
    assert [account.account_id for account in repository.list_accounts()] == ["A", "B"]


def test_missing_account_raises_domain_error():
    with pytest.raises(AccountNotFoundError):
        AccountRepository().get_account("missing")


def test_non_positive_transfer_is_rejected():
    repository = AccountRepository.with_demo_data()
    with pytest.raises(InvalidTransferError, match="greater than zero"):
        repository.transfer("ACC-1001", "ACC-1002", Decimal("0.00"))
