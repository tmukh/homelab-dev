# Kube Lab

A small site used to practice Kubernetes, growing one phase at a time.

## Layout

    web/        static frontend (HTML, CSS, JS, config.json)
    api/        (later) backend service
    k8s/        (you write these) Kubernetes manifests
    Dockerfile  (you write this) builds the web image

## What the frontend expects

- `config.json` holds the title and version. Bump `version` to "v2" to
  prove a rolling update worked. Later, a ConfigMap can overwrite it.
- `/api/health` is optional. If it answers with JSON like
  `{"hostname": "pod-name", "database": "ok"}`, the status cards light up.
  Until then they show "not deployed".

## Run locally before any container

    cd web
    python3 -m http.server 8080

Then open http://localhost:8080
