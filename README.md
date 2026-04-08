# Docker Service Shell

Independent Docker deployment shell for Node and Next.js services.

## What It Provides

- Production image build and runtime orchestration
- Health checks and unhealthy container auto-restart
- Main process restart with `restart: unless-stopped`
- Default route override to a side-router gateway
- Development mode with bind-mounted source and hot reload

## Files

- `Dockerfile`: shared multi-stage image
- `docker-compose.yml`: production stack
- `docker-compose.dev.yml`: development overrides
- `scripts/entrypoint.sh`: env validation and route setup
- `scripts/dev-start.sh`: dev dependency bootstrap and hot reload start
- `services/dub_precedent/.env.example`: service-specific example

## Production

1. Copy `services/dub_precedent/.env.example` to `.env`.
2. Fill in real PostgreSQL and app environment values.
3. Run database changes manually before release:

```bash
docker compose run --rm app npx prisma db push
```

4. Build and start:

```bash
docker compose up -d --build
```

5. Verify:

```bash
docker compose ps
docker compose logs -f app
docker compose exec app ip route
```

## Development

1. Copy `services/dub_precedent/.env.example` to `.env`.
2. Start the dev stack:

```bash
docker compose -f docker-compose.yml -f docker-compose.dev.yml up --build
```

3. Edit files in `../dub_precedent`. Next.js hot reload will run inside the container.

## Notes

- `ENABLE_DEFAULT_ROUTE_OVERRIDE=true` makes the app container run `ip route del default` and `ip route add default via ${DEFAULT_GATEWAY}` during startup.
- Only the app container gets `NET_ADMIN` and route changes.
- `autoheal` watches Docker health status and restarts unhealthy app containers.
- The default build command for `dub_precedent` is `npm run build:docker` so image builds do not modify the database schema.
- The build defaults to mainland-friendly mirrors: `APT_MIRROR=mirrors.tuna.tsinghua.edu.cn` and `NPM_REGISTRY=https://registry.npmmirror.com`. Override them in `.env` if another mirror is faster on your host.
- If PostgreSQL runs in Docker and the hostname is a container name such as `postgres`, set `POSTGRES_DOCKER_NETWORK` to the Docker network shared with that database container.
- If you want to validate Compose without copying the file first, set `ENV_FILE=services/dub_precedent/.env.example` together with `--env-file services/dub_precedent/.env.example`.

# docker-service-shell
