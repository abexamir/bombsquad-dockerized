# The official server binary is x86_64-only, so we pin the platform
# regardless of the host building the image (this intentionally
# overrides whatever --platform the build was invoked with).
FROM --platform=linux/amd64 ubuntu:24.04

ARG BOMBSQUAD_VERSION=1.7.43
ENV BOMBSQUAD_VERSION=${BOMBSQUAD_VERSION}
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        software-properties-common \
        ca-certificates \
        curl \
    && add-apt-repository -y ppa:deadsnakes/ppa \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        python3.13 \
        python3.13-dev \
        python3.13-venv \
    && apt-get purge -y software-properties-common \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Official server builds are fetched at image-build time rather than vendored in
# the repo, since they're distributed by the BombSquad project itself, not us.
RUN curl -fsSL \
        "https://files.ballistica.net/bombsquad/builds/old/BombSquad_Server_Linux_x86_64_${BOMBSQUAD_VERSION}.tar.gz" \
        -o /tmp/bombsquad_server.tar.gz \
    && mkdir -p /app \
    && tar -xzf /tmp/bombsquad_server.tar.gz -C /app --strip-components=1 \
    && rm /tmp/bombsquad_server.tar.gz \
    && chmod +x /app/bombsquad_server /app/dist/bombsquad_headless

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh \
    && useradd -m -s /usr/sbin/nologin bombsquad \
    && mkdir -p /data \
    && chown -R bombsquad:bombsquad /app /data

USER bombsquad
VOLUME ["/data"]
EXPOSE 43210/udp

ENTRYPOINT ["/entrypoint.sh"]
