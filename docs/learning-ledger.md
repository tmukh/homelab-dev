# Learning ledger

Status: **new** (introduced), **used** (used it, not explained back yet), **confident** (explained back correctly, or predicted right twice).

| Concept | Introduced in | Status | Last checked | Notes |
|---|---|---|---|---|
| Cluster, node (k3s on WSL2) | 0 | used | 2026-10-04 | |
| Namespace | 0 | used | 2026-10-04 | |
| Pod | 0 | used | 2026-10-04 | |
| Deployment -> ReplicaSet -> Pods | 0 | confident | 2026-10-01 | object chain answered correctly in the first quiz |
| Rolling update (maxSurge / maxUnavailable) | 0 | used | 2026-10-03 | watched with `get rs -w` during the ghcr switch |
| Scale vs template change (new ReplicaSet) | 0 | used | 2026-10-03 | earlier weak spot; seen but not explained back. Lab 4 |
| Labels and selectors, EndpointSlice | 0 | used | 2026-10-01 | weak spot: wrong selector means no endpoints. Lab 1 |
| Readiness vs liveness | 0 | used | 2026-10-04 | liveness answered right (restart). Readiness missed: it doesn't restart anything, it takes the pod out of the Service endpoints. Lab 3 |
| Causes of Pending (requests, scheduling) | 0 | new | 2026-10-01 | weak spot. Lab 2 |
| Ingress, Traefik 404 vs nginx 404 | 0 | used | 2026-10-01 | weak spot. Lab 5 |
| Describe-first debugging (Events) | 0 | confident | 2026-10-01 | |
| Image, registry, ghcr.io | 1 | used | 2026-10-03 | pull confirmed in `describe pod` Events |
| imagePullPolicy IfNotPresent | 1 | used | 2026-10-03 | second pod said "already present on machine" |
| Why SHA tags (quiz Q8) | 1 | new | | open |
| Write a Service from memory (quiz Q11) | 0 | new | | open |
| kubectl explain (quiz Q12, strategy) | 0 | new | | open |
| GitHub Actions workflow (on, paths, permissions) | 1 | used | 2026-10-03 | `.yml` vs `.yaml` path filter bug found and fixed |
| GitOps pull vs push | 1 | used | 2026-10-01 | earlier weak spot |
| Helm as consumer (install, values, pinned version) | 1 | used | 2026-10-03 | Argo CD chart 10.9.6 |
| CRD, `kubectl api-resources` | 1 | used | 2026-10-03 | used it to fix `argopo` |
| Argo CD Application | 1 | confident | 2026-10-05 | explained back: Application lives in argocd, destination.namespace is where its objects go; destination.server is the cluster API |
| Sync status vs health status | 1 | used | 2026-10-03 | |
| Argo tracking annotation (adoption) | 1 | used | 2026-10-03 | first OutOfSync on existing objects |
| Self-heal | 1 | used | 2026-10-03 | predicted "no clue", then saw it: 5 back to 2 |
| Prune | 1b | new | 2026-10-04 | |
| CreateNamespace=true | 1b | used | 2026-10-05 | knows it's a syncOptions flag ([]string). Missed: without it the sync fails with namespaces "labs" not found |
| Service DNS name (`<svc>.<ns>.svc`) | 1b | used | 2026-10-05 | kubernetes.default.svc is the API server's Service |
| syncPolicy.automated vs syncOptions | 1b | used | 2026-10-05 | |
| StatefulSet | 1 | new | 2026-10-03 | seen as argocd-application-controller-0 |
