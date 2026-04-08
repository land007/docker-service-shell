FROM node:20-bookworm-slim AS base

ARG APT_MIRROR=mirrors.tuna.tsinghua.edu.cn

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates \
    && sed -i "s|http://deb.debian.org/debian|https://${APT_MIRROR}/debian|g" /etc/apt/sources.list.d/debian.sources \
    && sed -i "s|http://deb.debian.org/debian-security|https://${APT_MIRROR}/debian-security|g" /etc/apt/sources.list.d/debian.sources \
    && apt-get update \
    && apt-get install -y --no-install-recommends bash curl dumb-init iproute2 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

ENV NEXT_TELEMETRY_DISABLED=1

FROM base AS deps

ARG APP_CONTEXT
ARG NPM_REGISTRY=https://registry.npmmirror.com

COPY ${APP_CONTEXT}/package.json ${APP_CONTEXT}/package-lock.json ./
RUN npm config set registry "${NPM_REGISTRY}"
RUN npm ci

FROM base AS builder

ARG APP_CONTEXT
ARG BUILD_COMMAND="npm run build"

COPY --from=deps /app/node_modules ./node_modules
COPY ${APP_CONTEXT}/ ./

RUN bash -lc "${BUILD_COMMAND}"
RUN npm prune --omit=dev

FROM base AS runner

ENV NODE_ENV=production

COPY --from=builder /app ./
COPY docker-service-shell/scripts/entrypoint.sh /opt/service-shell/entrypoint.sh
COPY docker-service-shell/scripts/dev-start.sh /opt/service-shell/dev-start.sh

RUN chmod +x /opt/service-shell/entrypoint.sh /opt/service-shell/dev-start.sh

ENTRYPOINT ["/usr/bin/dumb-init", "--", "/opt/service-shell/entrypoint.sh"]

FROM base AS devrunner

ENV NODE_ENV=development

ARG APP_CONTEXT
ARG NPM_REGISTRY=https://registry.npmmirror.com

COPY ${APP_CONTEXT}/package.json ${APP_CONTEXT}/package-lock.json ./
RUN npm config set registry "${NPM_REGISTRY}"
RUN npm ci

COPY docker-service-shell/scripts/entrypoint.sh /opt/service-shell/entrypoint.sh
COPY docker-service-shell/scripts/dev-start.sh /opt/service-shell/dev-start.sh

RUN chmod +x /opt/service-shell/entrypoint.sh /opt/service-shell/dev-start.sh

ENTRYPOINT ["/usr/bin/dumb-init", "--", "/opt/service-shell/entrypoint.sh"]
CMD ["/opt/service-shell/dev-start.sh"]
