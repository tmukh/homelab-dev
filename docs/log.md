# Log

Short notes on what I did each day and what I got stuck on.

## 2026-09-28

Started the repo and the first Kubernetes notes (01-Kubernetes.md). Components, objects, spec vs status.

## 2026-09-30 / 10-01

- Built the static site and an nginx Dockerfile, got it running on k3s.
- Wrote the namespace, deployment, service and ingress myself. The Ingress goes through Traefik.
- Restructured the repo into src/, deploy/, docs/ and labs/.
- GitHub Actions workflow that builds the image and pushes it to ghcr.io tagged sha-<commit>. Took three tries. Had to make the package public so the cluster can pull it without a secret.

## 2026-10-03

- Cleaned up old branches. Some looked unmerged but were squash merged, so `git branch -d` refuses them. Checked with `git diff` that the content was already on main before deleting with -D.
- Switched the Deployment from `kube-lab-web:v1` (imported by hand into containerd) to `ghcr.io/tmukh/kube-lab-web:sha-dac0da6`.
  - First `kubectl diff` failed with "mapping values are not allowed", a YAML typo on the image line.
  - `describe pod` showed `Pulling image "ghcr.io/..."` on the first pod. The second pod said "already present on machine", because imagePullPolicy is IfNotPresent and the first pod had already pulled it.
  - Watched the rollout with `kubectl get rs -w`, one new ReplicaSet, old one down to 0.
- Installed Argo CD with Helm (details in 04-argocd.md).
- Applied the kube-lab Application. Got the apiVersion group wrong and then the namespace (argo-cd instead of argocd). kubectl only shows one error at a time.
- First sync, then tested selfHeal with kubectl scale.

Next: break-it labs through Argo (second Application for labs/).
