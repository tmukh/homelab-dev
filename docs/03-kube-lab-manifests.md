# kube-lab manifests

Notes on the four objects I wrote for kube-lab (deploy/apps/kube-lab/) and the fields in them that actually matter.

The chain is: Deployment makes a ReplicaSet, the ReplicaSet makes the Pods. The Service finds the Pods by label, and the Ingress sends outside traffic to the Service.

```
Ingress -> Service -> (EndpointSlice) -> Pods <- ReplicaSet <- Deployment
```

## Namespace

Just a name. Everything else in kube-lab sets `metadata.namespace: kube-lab` so it lands in there. Deleting the namespace deletes everything inside it, which is worth remembering once Argo CD can prune.

## Deployment

Fields I care about:

- `spec.replicas` how many pods I want. Changing this only scales the existing ReplicaSet, it doesnt make a new one.
- `spec.selector.matchLabels` which pods this Deployment owns. It cant be changed after the Deployment is created, you have to delete and recreate it.
- `spec.template.metadata.labels` the labels every pod gets. They have to include everything in the selector or the apply is rejected.
- `spec.template.spec` the pod itself. Anything changed in here (image, probes, resources, env) gives a new pod-template-hash, so a new ReplicaSet and a rolling update.
- `image` the full registry path. k3s uses containerd and pulls from a registry, so it has to be `ghcr.io/tmukh/kube-lab-web:<tag>`, not a name that only exists in local Docker.
- `ports[].containerPort` 80, because the nginx image listens on 80. Naming it `http` means probes can say `port: http`.

### resources

- `requests` is what the scheduler reserves on a node. If no node has that much free, the pod stays Pending.
- `limits` is the ceiling. Going over the memory limit gets the container OOMKilled. Going over the cpu limit just throttles it.

### probes

- `readinessProbe` decides if the pod gets traffic. If it fails, the pod is taken out of the Service endpoints but keeps running. It also gates rollouts, the old pod isnt removed until the new one is ready.
- `livenessProbe` decides if the container is alive. If it fails, the kubelet restarts the container. A wrong path here means a restart loop (CrashLoopBackOff).

Both use `httpGet` on `/` with `port: http`. `initialDelaySeconds` is how long to wait before the first check, `periodSeconds` how often.

### rolling update

When I switched the image to ghcr I watched `kubectl get rs -w`. With 2 replicas and the defaults it went to 3 pods max and never below 2 ready. A new ReplicaSet came up, then the old one scaled to 0. The old ReplicaSet stays around (at 0) so `kubectl rollout undo` has something to go back to.

## Service

- `spec.selector` matches pod labels, not the Deployment's labels. If nothing matches, the Service still exists but has no endpoints.
- `ports[].port` the port the Service listens on (80).
- `ports[].targetPort` where it sends traffic on the pod. I used the number 80 instead of the name `http` so it keeps working if a pod during a rollout doesnt have the named port.
- `ports[].name: http` Prometheus will look for the port by name later.
- `type: ClusterIP` only reachable inside the cluster. The Ingress is the way in from outside.

`kubectl get endpointslice -n kube-lab` shows which pod IPs the Service actually points at. Empty means the selector is wrong or no pod is ready.

## Ingress

- `ingressClassName: traefik` which controller handles it. Traefik is the default on k3s.
- `rules[].http.paths[]` with `path: /` and `pathType: Prefix` so everything goes to the site.
- `backend.service.name` and `port.number` have to match the Service exactly.

If Traefik has no rule for a request I get Traefik's own 404. If the rule matches but the file doesnt exist, it's nginx's 404 page. That's how to tell which layer is wrong.

## Commands I use the most

```
kubectl get deploy,rs,pods,svc,ingress -n kube-lab -o wide
kubectl describe pod <pod> -n kube-lab      # Events at the bottom
kubectl get endpointslice -n kube-lab
kubectl diff -f deploy/apps/kube-lab/deployment.yaml
kubectl get rs -n kube-lab -w
```
