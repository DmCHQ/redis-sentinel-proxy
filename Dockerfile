FROM debian:bookworm-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends redis-tools socat && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

COPY sentinel-proxy.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

