# Disaster recovery

## Recovery boundaries

Pod recreation is automatically handled by Kubernetes, and PostgreSQL data survives because the StatefulSet reattaches its PVC. Colima shutdown also preserves the cluster. Deleting the PVC, kind cluster, or Colima disk can permanently remove database data.

## Create a logical PostgreSQL backup

Store generated backups only inside the ignored project `backups/` directory:

```bash
mkdir -p backups
kubectl --namespace muma-bank exec muma-bank-postgres-0 -- \
  pg_dump --username muma_bank --format=custom muma_bank \
  > backups/muma-bank.dump
```

Verify that the file is nonempty and keep it outside Git. A real production process would encrypt the backup and copy it to independently managed durable storage.

## Validate a backup

```bash
test -s backups/muma-bank.dump
kubectl --namespace muma-bank exec muma-bank-postgres-0 -- \
  pg_restore --list < backups/muma-bank.dump | head
```

Do not treat an untested backup as recoverable.

## Restore after an explicitly approved rebuild

1. Confirm the backup is readable before deleting anything.
2. Recreate Colima and kind from the pinned project configuration.
3. Rebuild and load the application image.
4. Initialize and apply Terraform.
5. Wait for the PostgreSQL StatefulSet and PVC to become Ready and Bound.
6. Copy the backup into the database Pod.
7. Restore into an empty database with `pg_restore`.
8. Validate account counts, balances, transfer behavior, and persistence across Pod recreation.
9. Reinstall ingress and observability, then run every validation target.

Exact destructive and restore commands should be reviewed at incident time because the correct flags depend on whether the target database is empty. Never automate deletion of the existing PVC as part of a restore script.

## Recovery objectives for this learning platform

- **RPO:** time of the most recent manual logical backup.
- **RTO:** operator-dependent local rebuild and restore time.
- **High availability:** not provided.

These are educational boundaries, not production banking commitments.
