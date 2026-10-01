# Platform overview

How the pieces of this homelab fit together, and the basics that should be second nature for each.

## The big picture

Three loops run independently:

1. **Build loop:** code becomes an image. A push to Git triggers GitHub Actions, which builds the image and stores it in the container registry (ghcr.io).
2. **Deploy loop (GitOps):** Git describes what should run. Argo CD, running inside the cluster, continuously compares the manifests in `deploy/` with what is live and makes the cluster match.
3. **Watch loop:** Prometheus scrapes metrics from the Pods and Grafana shows them.

Traffic takes its own path: browser, Cloudflare, tunnel into the cluster, Traefik, Service, Pod, Postgres.

## Components

| Component | One-line job | Lives in | Status |
|---|---|---|---|
| Git/GitHub | Single source of truth | whole repo | done |
| Docker image and registry | Packaged app, stored by tag | `src/` and ghcr.io | image done, registry next |
| GitHub Actions | Builds and pushes images on every change | `.github/workflows/` | next |
| Kubernetes (k3s) | Runs and heals containers | `deploy/apps/` | done |
| Argo CD | Makes the cluster match Git | `deploy/bootstrap/` | next |
| Helm | Templating and packaging for manifests | `deploy/` | later |
| ConfigMap, Secret, Sealed Secrets | Config and safe credentials | `deploy/apps/` | later |
| Postgres | The database, with storage | `deploy/apps/` | later |
| Prometheus and Grafana | Metrics and dashboards | `deploy/platform/` | later |
| Cloudflare Tunnel | Public access to the domain, no open ports | `deploy/platform/` | last |

## Container images and the registry

- **Mental model:** an image is an immutable stack of layers plus metadata. A registry stores images, and a tag is a movable label on one.
- **Second nature:** the name format `ghcr.io/<owner>/<name>:<tag>`. A tag can be reassigned, but a digest (`sha256:...`) cannot. Tag with the commit SHA so every image traces to one commit.
- **Gotchas:** a new ghcr package is usually private until its visibility is changed, and a private one needs `imagePullSecrets` on the cluster.

## GitHub Actions

- **Vocabulary:** a **workflow** is a YAML file in `.github/workflows/`. An **event** (`on:`) triggers it. It contains **jobs**, which run on **runners** (fresh VMs). Each job has **steps**, and a step either runs a shell command (`run:`) or uses a packaged **action** (`uses:`).
- **Second nature:** jobs run in parallel unless chained with `needs:`. Every job starts from a clean machine, so nothing carries over without artifacts or caches. `${{ github.sha }}` is the commit. Secrets come from `${{ secrets.NAME }}`. The built-in `GITHUB_TOKEN` can push packages only if the workflow grants `permissions: packages: write`.
- **Gotchas:** path filters (`paths:`) control which changes trigger a build. Commits pushed with `GITHUB_TOKEN` deliberately do not trigger new workflow runs, which prevents loops. Pull requests from forks do not get secrets. Pin action versions.
- **Where to look:** the Actions tab shows live logs for every step.

## Kubernetes

- **Core idea:** every controller runs a reconcile loop that compares desired state with actual state and closes the gap. A Deployment makes ReplicaSets, which make Pods. Argo CD works the same way, one level up.
- **Second nature:** `get`, `describe`, `logs`, `events`, `apply -f`, `diff`, `rollout status/undo`, `port-forward`. The status table (`Pending`, `ImagePullBackOff`, `CrashLoopBackOff`). Labels and selectors.

## Argo CD

- **What it is:** a set of controllers in the `argocd` namespace. It reads the Git repo, compares it with the live cluster, and syncs the cluster toward Git. It pulls from Git, so CI never needs credentials to the cluster.
- **Application:** a Kubernetes object saying "take this path in this repo at this revision and make it exist in this cluster and namespace". Fields: `source` (`repoURL`, `path`, `targetRevision`), `destination` (cluster and namespace), `syncPolicy`.
- **Statuses:** sync status is `Synced` or `OutOfSync`. Health status is `Healthy`, `Progressing`, `Degraded` or `Missing`.
- **Refresh vs sync:** refresh re-reads Git (by default Argo polls about every three minutes). Sync applies the difference.
- **Sync policy:** manual vs `automated`. `prune` deletes resources removed from Git. `selfHeal` reverts manual cluster changes.
- **AppProject:** a boundary limiting which repos and namespaces an Application may use.
- **Second nature:** reach the UI with `kubectl port-forward svc/argocd-server -n argocd 8080:443`. The first admin password is in the `argocd-initial-admin-secret` Secret. The CLI has `app list`, `app diff` and `app sync`.
- **Principle:** Git is the only way to change the cluster. Roll back with `git revert`, not by clicking in the UI.
- **Gotchas:** `selfHeal` undoes manual `kubectl` edits (intended). `prune` can delete things you forgot were managed. Namespaces need `CreateNamespace=true` or a manifest. An Application is itself a manifest, so an Application can manage Applications ("app of apps").

## Helm

- **Mental model:** a template engine plus a package format for Kubernetes manifests. A **chart** is a folder (`Chart.yaml`, `values.yaml`, `templates/`). A **release** is one installed instance of a chart.
- **Second nature:** `helm template` (render without installing), `helm lint`, `helm show values <chart>`, `helm install` and `helm upgrade --install`, `helm rollback`. Templating syntax is `{{ .Values.image.tag }}`. Value precedence: chart defaults, then `-f` files, then `--set`.
- **Gotchas:** indentation inside templates (`nindent`, `toYaml`), whitespace trimming with `{{-`, chart `version` and `appVersion` are different things. Under Argo CD, charts are rendered with `helm template`, so `helm list` does not show them.
- **Two roles:** first a consumer (installing other people's charts), later an author (packaging this app).

## ConfigMap, Secret, Sealed Secrets

- **ConfigMap:** key-value config, injected as environment variables or files.
- **Gotchas:** mounting a ConfigMap at a directory hides everything already in that directory, so replacing a single file needs `subPath`. But `subPath` files do not update when the ConfigMap changes, and environment variables only update after a Pod restart.
- **Secret:** same shape, but base64 is encoding, not encryption. Never commit one.
- **Sealed Secrets:** a controller in the cluster holds a private key. `kubeseal` encrypts a Secret into a `SealedSecret` that is safe in Git. By default it is bound to a specific name and namespace. Back up the controller's key, or a rebuilt cluster cannot decrypt anything.

## Postgres on Kubernetes

- **Pieces:** a StatefulSet (stable Pod name and its own volume), a volumeClaimTemplate creating a PVC from a StorageClass (k3s uses `local-path`, so data lives on the laptop's disk), a headless Service for a stable DNS name, and a Secret for the password.
- **Second nature:** connection strings use the Service DNS name (`name.namespace.svc.cluster.local`). Deleting a StatefulSet does not delete its PVCs. One replica is fine, but more than one needs real replication.
- **Gotchas:** volumes can come with a non-empty root, so set `PGDATA` to a subfolder. Plan backups (a `pg_dump` CronJob). Operators like CloudNativePG automate much of this.

## Prometheus and Grafana

- **Prometheus:** pulls metrics by scraping an HTTP `/metrics` endpoint on a schedule. A target is something it scrapes. Data is stored as labelled time series.
- **Metric types:** counter (only goes up), gauge (goes up and down), histogram (distribution, for latency).
- **PromQL basics:** `rate(counter[5m])`, `sum by (label) (...)`, `histogram_quantile`.
- **Operator objects** (from `kube-prometheus-stack`): `ServiceMonitor`, `PodMonitor`, `PrometheusRule`. The stack also includes Alertmanager, kube-state-metrics and node-exporter.
- **Gotchas:** a ServiceMonitor only works if its labels match what the Prometheus instance selects, and it finds the port by its name, which is why the Service port is named `http`. The stack is memory-hungry on a laptop.
- **Grafana:** reads data sources (Prometheus, later Loki for logs) and shows dashboards. For a service, think rate, errors, duration.

## Cloudflare Tunnel and the domain

- **How it works:** `cloudflared` runs inside the cluster and makes an outbound connection to Cloudflare. Cloudflare sends public traffic for the hostname back through it, so no router ports are opened.
- **DNS and TLS:** the domain's nameservers point at Cloudflare, and the hostname becomes a record pointing at the tunnel. TLS terminates at Cloudflare's edge, which `.dev` domains require.
- **Gotchas:** the tunnel token is a secret, so it needs Sealed Secrets first. The Ingress `host:` rule must match the public hostname. The site is only up while the laptop and WSL are running.

## The three flows

1. **Change flow:** edit code, `git push`, Actions builds `ghcr.io/.../kube-lab-web:<sha>`, the new tag goes into `deploy/` in Git, Argo CD notices, Kubernetes rolls out new Pods.
2. **Request flow:** browser, Cloudflare, tunnel, Traefik (Ingress rules), Service, Pod, API, Postgres.
3. **Watch flow:** Pods expose `/metrics`, Prometheus scrapes them, Grafana draws them.
