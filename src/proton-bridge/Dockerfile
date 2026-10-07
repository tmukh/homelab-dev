FROM debian:trixie-slim@sha256:a29215f6a35e51e22adffa17f89e9d2ef06214e64a2bad10d765c46aea49f11f

ARG BRIDGE_VERSION=3.27.0
ARG BRIDGE_SHA256=4ae1f9a38392379a08ab6cfb61b44078a339f55d1d366bbba0a0d9acf901e900

RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl gnupg pass \
 && curl -fsSL -o /tmp/bridge.deb "https://proton.me/download/bridge/protonmail-bridge_${BRIDGE_VERSION}-1_amd64.deb" \
 && echo "${BRIDGE_SHA256}  /tmp/bridge.deb" | sha256sum -c - \
 && apt-get install -y --no-install-recommends /tmp/bridge.deb \
 && apt-get purge -y curl \
 && apt-get autoremove -y \
 && rm -rf /var/lib/apt/lists/* /tmp/bridge.deb

RUN useradd --uid 10002 --home-dir /home/bridge --create-home --shell /usr/sbin/nologin bridge
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

USER 10002
ENV HOME=/home/bridge
VOLUME /home/bridge
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["--noninteractive"]
