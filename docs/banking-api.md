# Banking API

The Flask service is a deliberately small banking demo for container and Kubernetes learning. It uses the in-memory repository for local development and tests, and automatically uses PostgreSQL when `DATABASE_URL` is present.

## Start locally

```bash
make app-install
make app-test
make app-run
```

The server listens on `http://127.0.0.1:5000` for local development only.

Open `http://127.0.0.1:5000` in a browser for the responsive banking dashboard. It reads balances from the same API and submits transfers without a page reload.

## Health endpoints

```bash
curl http://127.0.0.1:5000/healthz
curl http://127.0.0.1:5000/readyz
```

`/healthz` reports process health. `/readyz` confirms the selected account repository is ready, including a live database query when PostgreSQL is configured. Kubernetes uses both paths as probes.

The PostgreSQL repository creates the account schema on startup, seeds demo accounts only when the table is empty, locks both account rows during transfers, and commits each debit and credit in one transaction.

## Accounts

List accounts:

```bash
curl http://127.0.0.1:5000/api/v1/accounts
```

Get one account:

```bash
curl http://127.0.0.1:5000/api/v1/accounts/ACC-1001
```

## Transfer funds

```bash
curl --request POST http://127.0.0.1:5000/api/v1/transfers \
  --header 'Content-Type: application/json' \
  --header 'X-Request-ID: demo-transfer-001' \
  --data '{
    "source_account_id": "ACC-1001",
    "destination_account_id": "ACC-1002",
    "amount": "125.50"
  }'
```

Amounts are handled with decimal arithmetic, must be positive, and may contain at most two decimal places. Transfers reject missing accounts, identical source and destination accounts, currency mismatches, and insufficient balances.

Every response includes an `X-Request-ID` header. Clients can supply one for correlation or allow the service to generate it.
