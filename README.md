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

## Usage

### 1. Prepare environment

Create a `.env` file in this directory and set the variables used by Compose, especially:

- `APP_CONTEXT`: app directory name located one level above this repository
- `IMAGE_NAME`: target image name
- `CONTAINER_NAME`: runtime container name
- `SERVICE_NAME`: service name prefix used by helper containers
- `HOST_PORT`: host port exposed to the outside
- `APP_PORT`: internal app port listened to by the Node/Next.js service
- `START_COMMAND`: production startup command, for example `npm run start`
- `POSTGRES_DOCKER_NETWORK`: existing Docker network name used to reach PostgreSQL

If you already have `services/dub_precedent/.env.example` in the parent project, you can copy it here as `.env` and adjust the values for your service.

### 2. Start production

Build and start the production stack:

```bash
docker compose up -d --build
```

Check service status:

```bash
docker compose ps
docker compose logs -f app
```

### 3. Start development

Run the development stack with bind-mounted source code and hot reload:

```bash
docker compose -f docker-compose.yml -f docker-compose.dev.yml up --build
```

Edit the application source under `../${APP_CONTEXT}` and the container will reload automatically.

### 4. Common operations

Stop services:

```bash
docker compose down
```

Rebuild after dependency or Dockerfile changes:

```bash
docker compose up -d --build
```

Open a shell in the app container:

```bash
docker compose exec app bash
```

Run a one-off command such as a database migration:

```bash
docker compose run --rm app <command>
```

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
