# Docker Service Shell

用于 Node 和 Next.js 服务的独立 Docker 部署外壳。

## 提供能力

- 生产环境镜像构建和运行编排
- 健康检查，以及不健康容器自动重启
- 通过 `restart: unless-stopped` 保证主进程自动恢复
- 支持把默认路由切到旁路网关
- 开发模式支持源码挂载和热更新

## 文件说明

- `Dockerfile`：通用多阶段镜像
- `docker-compose.yml`：生产环境编排
- `docker-compose.dev.yml`：开发环境覆盖配置
- `scripts/entrypoint.sh`：环境变量校验和路由设置
- `scripts/dev-start.sh`：开发依赖初始化和热更新启动
- `services/dub_precedent/.env.example`：服务示例环境变量文件

## 使用方法

### 1. 准备环境

在当前目录创建 `.env` 文件，并设置 Compose 运行所需的变量，重点包括：

- `APP_CONTEXT`：应用目录名，目录位于本仓库上一级
- `IMAGE_NAME`：目标镜像名
- `CONTAINER_NAME`：运行时容器名
- `SERVICE_NAME`：辅助容器使用的服务名前缀
- `HOST_PORT`：对外暴露的宿主机端口
- `APP_PORT`：Node/Next.js 服务在容器内监听的端口
- `START_COMMAND`：生产环境启动命令，例如 `npm run start`
- `POSTGRES_DOCKER_NETWORK`：用于连接 PostgreSQL 的现有 Docker 网络名

如果上级项目里已经有 `services/dub_precedent/.env.example`，可以先复制到这里作为 `.env`，再按你的服务实际情况修改。

### 2. 启动生产环境

构建并启动生产环境：

```bash
docker compose up -d --build
```

查看服务状态：

```bash
docker compose ps
docker compose logs -f app
```

### 3. 启动开发环境

使用源码挂载和热更新方式启动开发环境：

```bash
docker compose -f docker-compose.yml -f docker-compose.dev.yml up --build
```

直接修改 `../${APP_CONTEXT}` 下的应用源码，容器会自动热更新。

### 4. 常用操作

停止服务：

```bash
docker compose down
```

依赖或 Dockerfile 变更后重新构建：

```bash
docker compose up -d --build
```

进入应用容器的 Shell：

```bash
docker compose exec app bash
```

执行一次性命令，例如数据库迁移：

```bash
docker compose run --rm app <command>
```

## 生产环境

1. 复制 `services/dub_precedent/.env.example` 为 `.env`。
2. 填入真实的 PostgreSQL 和应用环境变量。
3. 发布前手动执行数据库变更：

```bash
docker compose run --rm app npx prisma db push
```

4. 构建并启动：

```bash
docker compose up -d --build
```

5. 验证运行状态：

```bash
docker compose ps
docker compose logs -f app
docker compose exec app ip route
```

## 开发环境

1. 复制 `services/dub_precedent/.env.example` 为 `.env`。
2. 启动开发环境：

```bash
docker compose -f docker-compose.yml -f docker-compose.dev.yml up --build
```

3. 修改 `../dub_precedent` 中的文件，Next.js 热更新会在容器内生效。

## 说明

- 设置 `ENABLE_DEFAULT_ROUTE_OVERRIDE=true` 后，应用容器启动时会执行 `ip route del default` 和 `ip route add default via ${DEFAULT_GATEWAY}`。
- 只有应用容器会获得 `NET_ADMIN` 权限并修改路由。
- `autoheal` 会监控 Docker 健康状态，并自动重启不健康的应用容器。
- `dub_precedent` 默认使用 `npm run build:docker` 进行构建，因此镜像构建过程不会修改数据库结构。
- 默认构建镜像使用大陆常用镜像源：`APT_MIRROR=mirrors.tuna.tsinghua.edu.cn` 和 `NPM_REGISTRY=https://registry.npmmirror.com`。如果宿主机访问其他镜像源更快，可以在 `.env` 中覆盖。
- 如果 PostgreSQL 运行在 Docker 中，且主机名是 `postgres` 这类容器名，需要把 `POSTGRES_DOCKER_NETWORK` 设置为与数据库容器共用的 Docker 网络。
- 如果你想在不复制文件的情况下验证 Compose，可以设置 `ENV_FILE=services/dub_precedent/.env.example`，并同时传入 `--env-file services/dub_precedent/.env.example`。
