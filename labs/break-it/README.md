# break-it labs

A small working app (traefik/whoami) that the `labs` Argo CD Application keeps in sync.
Each lab breaks one thing on purpose. Every break and every fix goes through Git:
self-heal is on, so a `kubectl edit` gets reverted within seconds.

## Baseline

- Deployment `whoami`: 2 replicas, listens on 8080, probes on `/health`
- Service `whoami`: port 80 to the pod port named `http`
- Ingress `whoami`: Traefik routes `/whoami` to the Service. `kube-lab-ingress` keeps `/`,
  Traefik prefers the longer path.

Check it works:

    kubectl -n labs get deploy,rs,pods,svc,endpointslices,ingress
    curl -s http://localhost/whoami        # prints the pod's hostname and the request

## The loop for every lab

1. Predict: write down what Argo, kubectl and curl will show.
2. Break: change one thing, commit, push, merge (or point the app at your branch).
3. Watch: Argo UI or k9s (`:applications`, `:pods`, `:ep`, `:events`).
4. Diagnose with `describe`, `logs`, `get events`, `get endpointslices`.
5. Fix with `git revert <sha>`, then confirm it is back to the baseline.
6. Write two lines in docs/log.md: the symptom and the command that exposed it.

## Labs

1. **Service selector that matches nothing** (service.yaml)
   Teaches: a Service finds pods only by label. Running pods, an existing Service, and
   still no traffic.

2. **Memory request bigger than the node** (deployment.yaml, resources)
   Teaches: requests are what the scheduler reserves. Why a pod stays Pending, and where
   the scheduler says why.

3. **Bad readiness path, then bad liveness path** (deployment.yaml, probes; one at a time)
   Teaches: readiness takes a pod out of the endpoints, liveness restarts it. Same mistake,
   two very different symptoms.

4. **Scale vs image change** (deployment.yaml; replicas, then the image tag)
   Teaches: only a change to spec.template makes a new ReplicaSet. Watch `get rs -w`.

5. **Ingress path that matches nothing** (ingress.yaml)
   Teaches: which component answers when no route matches, and how to tell Traefik's 404
   from the app's.
