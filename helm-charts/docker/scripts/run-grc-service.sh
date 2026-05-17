#!/bin/sh
set -eu

: "${SERVER_PORT:?SERVER_PORT is required}"
: "${JAR_PATH:?JAR_PATH is required}"
: "${LOG_PATH:?LOG_PATH is required}"
: "${LOG_FILENAME:?LOG_FILENAME is required}"
: "${SPRING_CONFIG:?SPRING_CONFIG is required}"

update_db_properties_if_needed() {
  if [ -z "${DB_HOST:-}" ] || [ -z "${DB_NAME:-}" ] || [ -z "${DB_USER:-}" ] || [ -z "${DB_PASSWORD:-}" ]; then
    echo "DB env vars incomplete; skipping config DB update"
    return
  fi

  port="${DB_PORT:-5432}"
  jdbc_opts="${DB_JDBC_OPTIONS:-}"
  jdbc_url="jdbc:postgresql://${DB_HOST}:${port}/${DB_NAME}"
  # Accept both file:////app/... and file:///app/... formats.
  config_path="${SPRING_CONFIG#file://}"

  if [ -n "$jdbc_opts" ]; then
    jdbc_opts="${jdbc_opts#\?}"
    jdbc_url="${jdbc_url}?${jdbc_opts}"
  fi

  if [ -f "$config_path" ]; then
    echo "Updating datasource in $config_path"
    sed -i "s|^[[:space:]]*spring.datasource.url[[:space:]]*=.*|spring.datasource.url=${jdbc_url}|" "$config_path"
    sed -i "s|^[[:space:]]*spring.datasource.username[[:space:]]*=.*|spring.datasource.username=${DB_USER}|" "$config_path"
    sed -i "s|^[[:space:]]*spring.datasource.password[[:space:]]*=.*|spring.datasource.password=${DB_PASSWORD}|" "$config_path"
    echo "Datasource updated: $(grep -E '^spring.datasource.url=' "$config_path" || true)"
    echo "Datasource user updated: $(grep -E '^spring.datasource.username=' "$config_path" || true)"
  else
    echo "Config path not found: $config_path; skipping datasource update"
  fi
}

if [ -x /usr/local/bin/run-config-init.sh ]; then
  if ! /bin/sh /usr/local/bin/run-config-init.sh; then
    echo "WARNING: run-config-init.sh failed; continuing with DB property update"
  fi
fi

update_db_properties_if_needed

# if [ -n "${MAIN_CLASS:-}" ]; then
#   exec java \
#     -Dserver.port="$SERVER_PORT" \
#     -Dlogging.config=file:////app/TargetAppResources/resources/log4j2.xml \
#     -Dlog-path="$LOG_PATH" \
#     -Dlog-filename="$LOG_FILENAME" \
#     -jar "$JAR_PATH" \
#     "$MAIN_CLASS" \
#     --spring.config.location="$SPRING_CONFIG"
# fi

# exec java \
#   -Dserver.port="$SERVER_PORT" \
#   -Dlogging.config=file:////app/TargetAppResources/resources/log4j2.xml \
#   -Dlog-path="$LOG_PATH" \
#   -Dlog-filename="$LOG_FILENAME" \
#   -jar "$JAR_PATH" \
#   --spring.config.location="$SPRING_CONFIG"

if [ -n "${MAIN_CLASS:-}" ]; then
  exec java \
    -Dserver.port="$SERVER_PORT" \
    -Dlogging.config=file:////app/TargetAppResources/resources/log4j2.xml \
    -Dlog-path="$LOG_PATH" \
    -Dlog-filename="$LOG_FILENAME" \
    -Djava.library.path=/usr/lib \
    -cp "$JAR_PATH:/app/lib/sapjco3.jar" \
    org.springframework.boot.loader.JarLauncher \
    --spring.config.location="$SPRING_CONFIG"
fi

exec java \
  -Dserver.port="$SERVER_PORT" \
  -Dlogging.config=file:////app/TargetAppResources/resources/log4j2.xml \
  -Dlog-path="$LOG_PATH" \
  -Dlog-filename="$LOG_FILENAME" \
  -Djava.library.path=/usr/lib \
  -cp "$JAR_PATH:/app/lib/sapjco3.jar" \
  org.springframework.boot.loader.JarLauncher \
  --spring.config.location="$SPRING_CONFIG"