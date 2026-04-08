#!/bin/bash
set -euo pipefail

validate_required_envs() {
  if [ -z "${REQUIRED_ENV_VARS:-}" ]; then
    return 0
  fi

  for env_name in ${REQUIRED_ENV_VARS}; do
    if [ -z "${!env_name:-}" ]; then
      echo "Missing required environment variable: ${env_name}" >&2
      exit 1
    fi
  done
}

configure_default_route() {
  if [ "${ENABLE_DEFAULT_ROUTE_OVERRIDE:-false}" != "true" ]; then
    return 0
  fi

  if [ -z "${DEFAULT_GATEWAY:-}" ]; then
    echo "DEFAULT_GATEWAY is required when ENABLE_DEFAULT_ROUTE_OVERRIDE=true" >&2
    exit 1
  fi

  echo "Current routing table:"
  ip route

  if ip route show default >/dev/null 2>&1; then
    ip route del default || true
  fi

  ip route add default via "${DEFAULT_GATEWAY}"

  echo "Updated routing table:"
  ip route
}

main() {
  validate_required_envs
  configure_default_route

  if [ "$#" -eq 0 ]; then
    echo "No startup command provided." >&2
    exit 1
  fi

  exec "$@"
}

main "$@"
