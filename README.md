# homelab-dev

A homelab Kubernetes platform (k3s on WSL2) deployed with GitOps. A learning project and portfolio.

## Layout

| Path | What lives there |
|---|---|
| src/ | Application source code and Dockerfiles. This is what CI builds. |
| deploy/apps/ | Kubernetes manifests, one folder per application |
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
