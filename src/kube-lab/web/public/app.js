"use strict";

// Runtime config lives in config.json so that, in a later phase, a Kubernetes
// ConfigMap can replace it without rebuilding the image.
const DEFAULT_CONFIG = { title: "Kube Lab", version: "unknown" };

function setCard(id, state, label, detail) {
  const card = document.getElementById("card-" + id);
  const stateEl = card.querySelector(".state");
  stateEl.dataset.state = state;
  stateEl.textContent = label;
  document.getElementById(id + "-detail").textContent = detail || " ";
}

async function fetchJson(url, timeoutMs) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);
  try {
    const res = await fetch(url, { cache: "no-store", signal: controller.signal });
    // A static server may answer unknown paths with index.html (HTTP 200).
    // Only accept a response that is really JSON.
    const type = res.headers.get("content-type") || "";
    if (!res.ok || !type.includes("application/json")) {
      return { ok: false, reason: "HTTP " + res.status + ", no JSON" };
    }
    return { ok: true, data: await res.json() };
  } catch (err) {
    return { ok: false, reason: err.name === "AbortError" ? "timed out" : "unreachable" };
  } finally {
    clearTimeout(timer);
  }
}

async function loadConfig() {
  const result = await fetchJson("config.json", 3000);
  return result.ok ? { ...DEFAULT_CONFIG, ...result.data } : DEFAULT_CONFIG;
}

async function refresh() {
  const config = await loadConfig();
  document.title = config.title;
  document.getElementById("site-title").textContent = config.title;
  document.getElementById("version").textContent = config.version;
  setCard("web", "ok", "running", "served as static files, " + config.version);

  setCard("api", "pending", "checking", "");
  setCard("db", "pending", "checking", "");

  const api = await fetchJson("/api/health", 3000);
  if (!api.ok) {
    setCard("api", "off", "not deployed", api.reason);
    setCard("db", "off", "not deployed", "needs the API first");
    return;
  }

  const body = api.data;
  setCard("api", "ok", "running", body.hostname ? "served by " + body.hostname : "");

  const db = body.database;
  if (db === "ok") setCard("db", "ok", "connected", "");
  else if (db) setCard("db", "bad", "problem", String(db));
  else setCard("db", "off", "not deployed", "API reports no database");
}

document.addEventListener("DOMContentLoaded", () => {
  document.getElementById("refresh").addEventListener("click", refresh);
  refresh();
  setInterval(refresh, 15000);
});
