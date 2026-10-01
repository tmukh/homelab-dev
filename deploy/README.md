# deploy/

Everything here is meant to be applied to the cluster: by hand while learning, by Argo CD later.

    apps/        one folder per application (plain manifests now, Helm charts later)
    platform/    cluster-wide tools: Argo CD, monitoring, sealed-secrets, cloudflared
    bootstrap/   Argo CD Application objects that point at the folders above

Apply an app by hand:

    kubectl apply -f deploy/apps/kube-lab/
