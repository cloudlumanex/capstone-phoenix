# Architecture

## 1. Topology diagram
Internet ──DNS──▶ taskapp.skylumanex.click / api.skylumanex.click

│

▼

ingress controller (node: cp1)  ──TLS terminated by cert-manager──┐

│                                                            │

▼                                                            ▼

frontend Service ──▶ frontend Pods (nodes: worker1, worker2)   backend Service ──▶ backend Pods (nodes: worker1, worker2)

│  /api proxy                              │

└────────────────────────────────────────▶│

▼

postgres Service ──▶ postgres-0 (PVC on node worker1)


## 2. Node & network

- **Nodes**: 1 control-plane (`cp1`, t3.small, eu-west-1a) + 2 workers (`worker1`, `worker2`, t3.micro, eu-west-1a). Control-plane runs Argo CD, ingress-nginx, cert-manager, Calico controllers. Workers run all TaskApp tier replicas.
- **CIDR / subnet**: VPC `10.0.0.0/16`, single public subnet `10.0.1.0/24` in eu-west-1a. A single subnet keeps the capstone's networking simple — the difficulty is Kubernetes orchestration, not multi-AZ subnet routing. All three nodes share one security group with self-referencing internal rules, so node-to-node traffic flows freely without being exposed externally.
- **Firewall**: Open to the world — port 22 (SSH, restricted to operator IP only), 80 (HTTP, redirects to HTTPS), 443 (HTTPS, ingress termination). Internal only (security-group-to-security-group) — all TCP/UDP between nodes, covering the Kubernetes API (6443), kubelet (10250), and Calico VXLAN (UDP 4789). **Port 6443 is never opened to `0.0.0.0/0`** — it is reachable only from within the node security group and, separately, from the operator's own IP for `kubectl` access from a laptop. This satisfies the hard constraint that the Kubernetes API must never be exposed to the internet at large.

## 3. Request flow

A request to `taskapp.skylumanex.click` resolves via Route 53 to the control-plane's static Elastic IP, where **ingress-nginx** terminates TLS using a certificate issued by **cert-manager** against Let's Encrypt. The ingress routes `/` to the `frontend` ClusterIP Service (port 80), which load-balances across two frontend Pods running nginx and the built React assets. The frontend's API calls to `/api` are routed by the same ingress to the `backend` ClusterIP Service (port 5000), load-balanced across two Flask backend Pods. The backend connects to Postgres via the `postgres` ClusterIP Service on port 5432, resolved internally as `postgres.taskapp.svc.cluster.local`, which targets the single Postgres Pod managed by a StatefulSet with its PVC.

## 4. The single-server assumptions you fixed

| Single-server assumption | Why it breaks at scale | How you fixed it |
|---|---|---|
| migrate-on-boot in the entrypoint | 2+ replicas race on `alembic upgrade head`, corrupting the schema | Migrations run as a Kubernetes Job, executed once to completion before the backend Deployment rolls out |
| named volume on the host | Pods reschedule across nodes; a host-local volume would not follow Postgres to a new node | Postgres runs as a StatefulSet with a PVC backed by the cluster's default StorageClass (EBS), giving it a stable identity and network-attached storage independent of which node it lands on |
| `ports:` published on the host | Many Pods, many nodes — there is no single host to publish a port on | A single ingress-nginx controller is the one front door; Services and ClusterIPs route traffic internally regardless of which node a Pod is scheduled to |
| process restart = brief downtime, acceptable on one box | At 2+ replicas, naive restarts can drop all healthy replicas simultaneously | RollingUpdate strategy with `maxUnavailable: 0`, gated by readiness probes, ensures at least one healthy replica serves traffic throughout any deploy |
| SSH in and restart the process when something hangs | No human is watching a 3-node cluster constantly; node or pod failure must self-heal | Liveness/readiness/startup probes let Kubernetes detect and restart unhealthy containers automatically; the Deployment controller reschedules Pods from a dead node onto a healthy one |
| `.env` file or plaintext config on the host | Secrets and config must travel with Pods across nodes, never live in git | Non-secret config lives in a ConfigMap; secrets are created out-of-band via `kubectl apply` from a local, gitignored file and consumed via environment variables in the Deployments |

## 5. Choices & trade-offs

- **Raw YAML vs Helm vs kustomize**: Raw YAML, organised by concern (`platform/`, `taskapp/database`, `taskapp/backend`, etc). Every object is immediately auditable without a render step — appropriate for a capstone graded on Kubernetes object understanding rather than packaging tooling.
- **ingress-nginx vs k3s Traefik**: ingress-nginx was chosen and Traefik disabled at install time (`--disable traefik`). ingress-nginx has clearer, more widely documented `cert-manager` annotation support, and the reference K8s lesson manifests already targeted it.
- **CNI / NetworkPolicy enforcement**: k3s ships Flannel by default, which does not enforce NetworkPolicy. Flannel was disabled at install time (`--flannel-backend=none --disable-network-policy`) and replaced with **Calico**. Calico's default BGP-based routing (`ipipMode: Always`) does not reliably establish BGP peering between EC2 nodes in the same security group — `calico-node` pods reported `BIRD is not ready: BGP not established` indefinitely. The fix: switch Calico to **VXLAN encapsulation** (`calico_backend: vxlan`, `vxlanMode: Always`), which uses standard UDP traffic already permitted by the security group's internal rules, and strip the BIRD-based readiness/liveness checks from the `calico-node` daemonset since BIRD does not run in VXLAN-only mode. This is fully automated in the `k3s-server` Ansible role.
- **Secrets approach**: out-of-band. `secret.yaml.example` is committed to show the expected keys; the real `Secret` is created locally from a gitignored file and applied once, then owned by Argo CD going forward. The stretch goal of Sealed Secrets / External Secrets Operator was not implemented in this iteration.