# Kube Lab

A small static site that grows into a full stack: API, database, GitOps and monitoring.

## Layout

    web/       Dockerfile, .dockerignore and public/ (the site files)
    api/       (later) backend service

Its Kubernetes manifests live in deploy/apps/kube-lab/.

## What the frontend expects

- public/config.json holds the title and version. Bump the version to prove a rollout worked.
- /api/health is optional. If it answers with JSON like {"hostname": "pod", "database": "ok"},
  the status cards light up. Until then they show "not deployed".

## Run locally (from the repo root)

    cd src/kube-lab/web/public && python3 -m http.server 8080

## Build and test the image (from the repo root)

    docker build -t kube-lab-web:v1 src/kube-lab/web
    docker run --rm -p 8081:80 kube-lab-web:v1
