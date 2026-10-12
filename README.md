# homelab-dev

A homelab Kubernetes platform (k3s on WSL2) deployed with GitOps. A learning project and portfolio.

## Layout

| Path | What lives there |
|---|---|
| src/ | Application source code and Dockerfiles. This is what CI builds. |
| deploy/apps/ | Kubernetes manifests, one folder per application |
| charts/app/ | Shared base chart: Deployment, Service, NetworkPolicy, CronJobs, Ingress, ServiceMonitor (PSS restricted) |
| deploy/platform/ | Cluster-wide tooling: Argo CD, monitoring, sealed-secrets, cloudflared |
| deploy/bootstrap/ | Argo CD Application objects that point at the folders above |
| .github/workflows/ | CI pipelines |
| docs/ | Learning notes |
| labs/ | Throwaway experiments, never deployed |

## Rules

1. Anything under deploy/ may be applied to the cluster. Experiments go in labs/.
2. CI reacts to changes in src/ only, never to deploy/, so a CI commit can not trigger another build.
3. No secrets in Git. Plain Kubernetes Secrets are only base64, not encrypted.

## Apps

- kube-lab: static site, later an API and a Postgres database. See src/kube-lab/README.md.
- application-tracker: tailnet only.
- night-sky-digest: API, website and nightly CronJobs on the shared chart (charts/app), CloudNativePG
  database, public at https://digest.takodana.dev via Cloudflare Tunnel.

## Platform

| Component | What for |
|---|---|
| Argo CD (app of apps) | GitOps: everything under deploy/ is synced from main |
| Sealed Secrets | Secrets in Git; seal with scripts/seal_secret.py (cert in deploy/platform/sealed-secrets) |
| Tailscale operator | Tailnet-only access (Grafana, Langfuse, tracker, dev DB) and egress to Ollama |
| cloudflared | The only public route (locally managed tunnel, routing in config.yaml) |
| cert-manager | Webhook certificates for the ClickHouse operator and the Barman plugin |
| CloudNativePG + Barman Cloud plugin | Postgres clusters with WAL archiving and nightly backups |
| backup-store (SeaweedFS) | S3 for Postgres backups (same disk: protects against mistakes, not disk loss) |
| kube-prometheus-stack | Prometheus, Alertmanager (Telegram), Grafana |
| Loki + Alloy | Pod logs, 7 days |
| Langfuse (+ ClickHouse operator) | LLM traces for night-sky-digest |
