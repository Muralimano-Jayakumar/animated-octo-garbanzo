# Local multi-node kind cluster

The local Kubernetes environment runs inside Colima and uses kind to create one control-plane and two worker nodes.

## Topology

| Node | Role | Project label |
| --- | --- | --- |
| `muma-bank-control-plane` | control-plane | `ingress-ready=true` |
| `muma-bank-worker` | worker | `workload-tier=application` |
| `muma-bank-worker2` | worker | `workload-tier=data` |

The Kubernetes API listens only on `127.0.0.1:6443`. Ingress traffic uses loopback ports `8081` and `8443`, so it is not exposed on the Mac's external interfaces.

The cluster pins Kubernetes v1.36.1 to the node digest published with kind v0.32.0.

## Create and validate

```bash
colima start --cpu 4 --memory 8 --disk 60
make cluster-create
make cluster-validate
```

The create script is idempotent: if `muma-bank` already exists, it exits without replacing it.

## Load the application image

Build the image if it is not already stored in Colima, then load it into each node:

```bash
make container-build
make container-scan
make cluster-load-image
```

Loading an image does not deploy a Pod or other Kubernetes workload.

## Install the ingress add-on

```bash
make ingress-install
```

The script installs the pinned ingress-nginx kind manifest and waits for the controller. Application routing remains managed separately by Terraform. See [Ingress and local networking](ingress-local-networking.md).

## Inspect resources

```bash
kind get clusters
kubectl config current-context
kubectl get nodes --output=wide
kubectl get pods --all-namespaces --output=wide
docker ps --filter label=io.x-k8s.kind.cluster=muma-bank
```

## Stop without deleting

Stop Colima to release CPU and memory while preserving the cluster containers and images:

```bash
colima stop
```

On the next session:

```bash
colima start
make cluster-validate
```

## Delete intentionally

Deletion is not part of normal shutdown. When the cluster is no longer needed, review its exact name and confirm explicitly:

```bash
kind get clusters
CONFIRM_DELETE=muma-bank make cluster-delete
```

This removes the `muma-bank` kind cluster and its node containers. It does not delete Colima or unrelated Docker resources.
