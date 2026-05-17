#!/bin/sh
set -eu

SCHEDULAR_CONFIG="${SCHEDULAR_CONFIG:-/app/AccessHubSchedular/schedular.properties}"
case "$SCHEDULAR_CONFIG" in
  file://*) SCHEDULAR_CONFIG_PATH="${SCHEDULAR_CONFIG#file://}" ;;
  *) SCHEDULAR_CONFIG_PATH="$SCHEDULAR_CONFIG" ;;
esac

update_db_properties_if_needed() {
  if [ -z "${DB_HOST:-}" ] || [ -z "${DB_NAME:-}" ] || [ -z "${DB_USER:-}" ] || [ -z "${DB_PASSWORD:-}" ]; then
    echo "DB env vars incomplete; skipping schedular.properties DB update"
    return
  fi

  port="${DB_PORT:-5432}"
  jdbc_opts="${DB_JDBC_OPTIONS:-}"
  jdbc_url="jdbc:postgresql://${DB_HOST}:${port}/${DB_NAME}"

  if [ -n "$jdbc_opts" ]; then
    jdbc_opts="${jdbc_opts#\?}"
    jdbc_url="${jdbc_url}?${jdbc_opts}"
  fi

  if [ -f "$SCHEDULAR_CONFIG_PATH" ]; then
    echo "Updating datasource in $SCHEDULAR_CONFIG_PATH"
    sed -i "s|^[[:space:]]*spring.datasource.url[[:space:]]*=.*|spring.datasource.url=${jdbc_url}|" "$SCHEDULAR_CONFIG_PATH"
    sed -i "s|^[[:space:]]*spring.datasource.username[[:space:]]*=.*|spring.datasource.username=${DB_USER}|" "$SCHEDULAR_CONFIG_PATH"
    sed -i "s|^[[:space:]]*spring.datasource.password[[:space:]]*=.*|spring.datasource.password=${DB_PASSWORD}|" "$SCHEDULAR_CONFIG_PATH"
    echo "Datasource updated: $(grep -E '^spring.datasource.url=' "$SCHEDULAR_CONFIG_PATH" || true)"
    echo "Datasource user updated: $(grep -E '^spring.datasource.username=' "$SCHEDULAR_CONFIG_PATH" || true)"
  else
    echo "Schedular config not found at $SCHEDULAR_CONFIG_PATH; skipping DB update"
  fi
}

if [ -x /usr/local/bin/run-config-init.sh ]; then
  if ! /bin/sh /usr/local/bin/run-config-init.sh; then
    echo "WARNING: run-config-init.sh failed; continuing with DB property update"
  fi
fi

update_db_properties_if_needed

if [ "${1:-}" = "--update-only" ]; then
  echo "Update-only mode complete; exiting before Java startup"
  exit 0
fi

exec java \
  -Dserver.port=8070 \
  -Dlogging.config=file:////app/TargetAppResources/resources/log4j2.xml \
  -Dlog-path=/app/log/AccessHubSchedular \
  -Dlog-filename=AccessHubSchedular \
  -jar /app/AccessHubSchedular/AccessHubSchedular-0.0.1-SNAPSHOT.jar \
  --spring.config.location=file:////${SCHEDULAR_CONFIG_PATH#/}
