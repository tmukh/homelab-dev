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

## 2026-10-07: Application Tracker on the cluster

Got the Application Tracker running on k3s, managed by Argo CD, reachable only over Tailscale at https://tracker.tailadc3fe.ts.net.

What I set up:
- A root Application (app of apps) for deploy/bootstrap/apps. Argo now manages itself, plus Sealed Secrets and the Tailscale operator, all from pinned Helm charts. Never `helm uninstall argocd` again, upgrades go through targetRevision.
- The Tailscale OAuth secret is a SealedSecret in Git. Only the controller in the cluster can decrypt it. The controller key is backed up offline, without it a rebuilt cluster can't read any sealed secret.
- My own Proton Bridge image (src/proton-bridge), built by CI and pushed to ghcr.io. The .deb is pinned by sha256 after checking Proton's signature.
- Tracker and Bridge run in one pod, so the app talks IMAP to 127.0.0.1:1143 and mail never crosses the network.
- Namespace is Pod Security restricted: non-root, read-only root filesystem, drop ALL. Writable stuff goes to PVCs and an emptyDir on /tmp.
- NetworkPolicy: only the tailscale namespace can reach port 5055. Out: DNS, Ollama on 11434, and 443 to the internet for Proton.
- All cluster-specific values (image tags, Ollama address, mailbox) live in kustomization.yaml.
- Checked it all: dashboard from my phone, settings save, folders list, mails classified by qwen2.5:7b, data and Proton login survive a pod delete, another namespace can't reach the app, the backup job writes a valid copy.

Things I learned:
- Proton's launcher starts the GUI and updates itself, so the image runs the core bridge binary. Bridge only opens IMAP after an account is logged in.
- Scaling to 0 for the login needed ignoreDifferences on /spec/replicas AND RespectIgnoreDifferences=true, otherwise self-heal puts it back to 1.
- A liveness probe shouldn't depend on the network. Argo's repo-server restarted 202 times because its full health check timed out during network blips.
- Pods reach Ollama on my PC because Tailscale runs inside WSL. Pod traffic leaves with the node's tailnet IP.
- local-path deletes the data when a PVC is deleted, so the namespace and PVCs have Prune=false,Delete=false for Argo.
- Tailscale's proxy keeps the Host header, so the app's Origin check works without changes.
- I still had an old copy running by hand on the laptop behind `tailscale serve`. Two copies meant two databases and double the Ollama work, so I shut it down.
- Backups are on the same disk for now. Good against a bad migration, not against losing the laptop.
