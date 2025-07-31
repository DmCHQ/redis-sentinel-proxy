# Redis Sentinel TCP Proxy

This container provides a transparent TCP proxy that regularly queries Redis Sentinel for the current Redis master and automatically forwards all incoming connections to it. This enables high-availability Redis connections without requiring direct Sentinel support in the client application.

## ✅ Features

- 🔁 publish master detected by Redis Sentinel
- 🔄 failover switch 
- 🐳 Swarm ready

## ⚙️  ENV

| ENV                    |  default       | mandatory    |
|------------------------|----------------|--------------|
| `REDIS_SENTINEL_HOSTS` | –              |     ✅       |
| `SENTINEL_MASTER_NAME` | –              |     ✅       |
| `REDIS_SENTINEL_PORT`  | `26379`        |     ❌       |
| `REDIS_SESSION_PORT`   | `6379`         |     ❌       |
| `LISTEN_PORT`          | `9736`         |     ❌       |
| `LISTEN_HOST`          | `127.0.0.1`    |     ❌       |

---

## 🧪 Stack deploy

```yaml

services:
  redis-proxy:
    image: ghcr.io/DmCHQ/redis-sentinel-proxy:latest
    ports:
      - "9736:9736"
    environment:
      REDIS_SENTINEL_HOSTS: "sentinel1 sentinel2 sentinel3"
      SENTINEL_MASTER_NAME: "mymaster"
      # optional envs:
      REDIS_SENTINEL_PORT: 26379
      REDIS_SESSION_PORT: 6379
      LISTEN_PORT: 9736
      LISTEN_HOST: "0.0.0.0"
    networks:
      - sentinel_network
    deploy:
      placement:
        constraints:
          - node.labels.tag == fancytag

networks:
  sentinel_network:
    external: true
```

---

## 🧯 Failover

- `socat` will burned and restarted
- Last known master will stay active.

---

## 📡 Usage with clients who do not speak Sentinel

point em to service with port:

```bash
redis-cli -h redis-proxy -p 9736
```

Connection will be transparently routed to master.

---

## 🛠 Build & Deployment


```bash
docker build -t redis-sentinel-proxy .
docker run --rm \
  -e REDIS_SENTINEL_HOSTS="sentinel1 sentinel2" \
  -e SENTINEL_MASTER_NAME="mymaster" \
  -p 9736:9736 \
  redis-sentinel-proxy
```

---

## 📜 Lizenz

MIT License 
