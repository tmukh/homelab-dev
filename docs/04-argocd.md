# Argo CD

Argo CD runs inside the cluster and keeps it matching what's in Git. It compares the manifests in a repo folder with what's live, shows the difference, and can apply it. The cluster pulls from Git, so CI never needs credentials to the cluster.

## How I installed it

With the Helm chart, pinned so it's the same every time:

```
helm repo add argo https://argoproj.github.io/argo-helm
helm install argocd argo/argo-cd --version 10.9.6 \
  -n argocd --create-namespace -f deploy/platform/argocd/values.yaml
```

What I changed in values.yaml and why:

- `configs.params.server.insecure: true` the server serves plain http. I only reach it with port-forward for now, and later TLS will end at Traefik or Cloudflare. It doesnt turn off the login.
- `dex.enabled: false` dex is for SSO. I'm the only user so I dont need it.
- `notifications.enabled: false` nothing to send alerts to yet.

Everything else is the chart default. `helm show values argo/argo-cd` shows all of them.

## What's running

```
argocd-application-controller-0     the loop that compares Git and live and syncs
argocd-repo-server                  clones the repo and renders the manifests
argocd-server                       API and the web UI
argocd-redis                        cache
argocd-applicationset-controller    makes Applications from a template (later)
```

The controller is a StatefulSet (that's why it ends in -0, not a random hash).

Getting in:

```
kubectl port-forward svc/argocd-server -n argocd 8080:443
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
```

Then http://localhost:8080, user admin. Change the password and delete that secret after.

## Application

Installing Argo CD added new kinds to the cluster (CRDs): Application, ApplicationSet, AppProject. An Application is just another object that says "take this folder from this repo and make it exist in this namespace".

The fields in deploy/bootstrap/kube-lab-app.yaml:

- `apiVersion: argoproj.io/v1alpha1` I got this wrong first (typed argopo). `kubectl api-resources | grep application` shows the right group.
- `metadata.namespace: argocd` the Application lives in Argo's namespace, not in kube-lab.
- `spec.project: default` AppProjects can limit repos and namespaces, default allows everything.
- `source.repoURL` the https url. The repo is public so no credentials. The git@ url would need a deploy key.
- `source.path: deploy/apps/kube-lab` every yaml in here becomes desired state.
- `source.targetRevision: main` merging to main is the deploy.
- `destination.server: https://kubernetes.default.svc` means this same cluster.
- `destination.namespace: kube-lab`
- `syncPolicy.automated` sync on its own when Git changes.
  - `prune` delete live objects that were removed from Git. Off for kube-lab for now, since namespace.yaml is in that folder.
  - `selfHeal` undo changes made directly in the cluster.

The first Application has to be applied by hand with kubectl, Argo cant deploy the thing that tells it what to deploy. Argo also isnt watching deploy/bootstrap/, so changes to this file still need a kubectl apply. App of apps fixes that later.

## Sync and health

Two separate things:

- sync status: Synced or OutOfSync. Does live match Git.
- health: Healthy, Progressing, Degraded, Missing. Is it actually working.

OutOfSync + Healthy means it works but isn't what Git says. Synced + Degraded means it's exactly what Git says and Git is broken.

## What happened when I added kube-lab

It came up OutOfSync + Healthy even though the content matched Git. Argo marks everything it manages with an annotation (`argocd.argoproj.io/tracking-id`), and my objects were made with plain kubectl apply so they didnt have it. After a sync it was Synced. The pods were not recreated, because the annotation is on the Deployment's metadata, not in spec.template.

## Self heal test

I ran `kubectl scale deploy kube-lab-web -n kube-lab --replicas=5`.

- automated, selfHeal off: stayed at 5 and showed OutOfSync. Argo only acts when Git changes.
- turned selfHeal on: it went straight back to 2 without me scaling again, because the drift was already there.

Argo didnt delete the pods itself. It set replicas back to 2 on the Deployment, the Deployment scaled the ReplicaSet, and the ReplicaSet deleted 3 pods. It removed the newest ones and kept the two old pods.

So with selfHeal on, kubectl is for looking and Git is for changing.

## Things to remember

- Roll back with git revert, not by clicking in the UI.
- If an HPA is added later, take `replicas` out of Git or Argo and the HPA fight.
- The `resources-finalizer.argocd.argoproj.io` finalizer makes deleting the Application delete everything it manages. Not using it yet.
- Argo checks Git about every 3 minutes. Refresh in the UI to check now.
