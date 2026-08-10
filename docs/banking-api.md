# Banking API

The Flask service is a deliberately small banking demo for container and Kubernetes learning. It keeps data in memory during this phase; PostgreSQL persistence is planned separately.

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

`/healthz` reports process health. `/readyz` confirms the account repository is ready. These paths are intended for future Kubernetes probes.

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
