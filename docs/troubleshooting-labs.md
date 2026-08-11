# Kubernetes troubleshooting labs

These labs reproduce four common failures in the isolated `muma-bank-labs` namespace. They never modify the application, PostgreSQL, ingress, or monitoring namespaces.

## Workflow

```bash
colima start --cpu 4 --memory 8 --disk 60
make cluster-validate
make container-build
make cluster-load-image
make troubleshooting-apply
make troubleshooting-validate
```

Inspect the evidence before recovering:

```bash
kubectl --namespace muma-bank-labs get pods,pvc
kubectl --namespace muma-bank-labs get events --sort-by=.metadata.creationTimestamp
kubectl --namespace muma-bank-labs describe deployment image-pull-lab
kubectl --namespace muma-bank-labs describe deployment readiness-lab
kubectl --namespace muma-bank-labs logs dns-lab
kubectl --namespace muma-bank-labs describe pvc storage-lab
```

Then recover and validate:

```bash
make troubleshooting-recover
kubectl --namespace muma-bank-labs get pods,pvc
```

## Lab 1: image unavailable

- Symptom: Pod remains Pending with `ErrImageNeverPull`.
- Evidence: container status and events show `muma-bank:missing` is absent locally while pull policy is `Never`.
- Root cause: the workload references an image that was not loaded into kind.
- Recovery: use the loaded `muma-bank:dev` image.
- Prevention: build and load immutable image references before applying workloads.

## Lab 2: readiness probe failure

- Symptom: container is Running but Pod readiness remains `0/1`.
- Evidence: events show HTTP probe failures against `/wrong-readiness-path`.
- Root cause: the probe path does not exist.
- Recovery: point the readiness probe at `/readyz`.
- Prevention: exercise probe paths in tests and deployment smoke checks.

## Lab 3: DNS resolution failure

- Symptom: diagnostic Pod exits Failed with a name-resolution exception.
- Evidence: logs reference `missing-service.muma-bank.svc.cluster.local`.
- Root cause: the service name is incorrect.
- Recovery: resolve the real FQDN `muma-bank.muma-bank.svc.cluster.local`.
- Prevention: inspect Services and EndpointSlices and prefer generated configuration over manually repeated names.

## Lab 4: persistent storage pending

- Symptom: PVC stays Pending.
- Evidence: PVC events report that `unavailable-storage-class` does not exist.
- Root cause: an invalid StorageClass was requested.
- Recovery: recreate the lab claim with kind's `standard` class and attach a consumer Pod.
- Prevention: validate StorageClass availability and understand `WaitForFirstConsumer` binding.

## Guarded cleanup

Normal cleanup requires an exact confirmation:

```bash
CONFIRM_DELETE=muma-bank-labs make troubleshooting-cleanup
```

The script contains the fixed namespace name and cannot accept another target. Lab PVC data is intentionally disposable and is deleted with this namespace. The real `muma-bank` PVC is not selected.

Finally release local runtime resources:

```bash
colima stop
```
