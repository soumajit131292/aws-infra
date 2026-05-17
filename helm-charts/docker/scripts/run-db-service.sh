# #!/bin/sh
# set -eu

# : "${SERVER_PORT:?SERVER_PORT is required}"
# : "${JAR_PATH:?JAR_PATH is required}"

# DATABASE="${DATABASE:-POSTGRES}"
# if [ "$DATABASE" = "MONGODB" ]; then
#   SPRING_CONFIG="file:////app/TargetAppResources/resources/mongoDB/application.properties"
# else
#   SPRING_CONFIG="file:////app/TargetAppResources/resources/postGresDB/application.properties"
# fi

# update_db_properties_if_needed() {
#   if [ "${DATABASE}" != "POSTGRES" ]; then
#     return
#   fi

#   if [ -z "${DB_HOST:-}" ] || [ -z "${DB_NAME:-}" ] || [ -z "${DB_USER:-}" ] || [ -z "${DB_PASSWORD:-}" ]; then
#     return
#   fi

#   port="${DB_PORT:-5432}"
#   jdbc_opts="${DB_JDBC_OPTIONS:-}"
#   jdbc_url="jdbc:postgresql://${DB_HOST}:${port}/${DB_NAME}"
#   # Accept both file:////app/... and file:///app/... formats.
#   config_path="${SPRING_CONFIG#file://}"

#   if [ -n "$jdbc_opts" ]; then
#     jdbc_opts="${jdbc_opts#\?}"
#     jdbc_url="${jdbc_url}?${jdbc_opts}"
#   fi

#   if [ -f "$config_path" ]; then
#     sed -i "s|^[[:space:]]*spring.data.postgre.connectionurl[[:space:]]*=.*|spring.data.postgre.connectionurl=${jdbc_url}|" "$config_path"
#     sed -i "s|^[[:space:]]*spring.data.postgre.username[[:space:]]*=.*|spring.data.postgre.username=${DB_USER}|" "$config_path"
#     sed -i "s|^[[:space:]]*spring.data.postgre.password[[:space:]]*=.*|spring.data.postgre.password=${DB_PASSWORD}|" "$config_path"
#     sed -i "s|^[[:space:]]*spring.datasource.url[[:space:]]*=.*|spring.datasource.url=${jdbc_url}|" "$config_path"
#     sed -i "s|^[[:space:]]*spring.datasource.username[[:space:]]*=.*|spring.datasource.username=${DB_USER}|" "$config_path"
#     sed -i "s|^[[:space:]]*spring.datasource.password[[:space:]]*=.*|spring.datasource.password=${DB_PASSWORD}|" "$config_path"
#   fi
# }

# if [ -x /usr/local/bin/run-config-init.sh ]; then
#   if ! /bin/sh /usr/local/bin/run-config-init.sh; then
#     echo "WARNING: run-config-init.sh failed; continuing with DB property update"
#   fi
# fi

# update_db_properties_if_needed

# exec java -Dserver.port="$SERVER_PORT" -jar "$JAR_PATH" --spring.config.location="$SPRING_CONFIG"


# #!/bin/sh
# set -eu

# : "${SERVER_PORT:?SERVER_PORT is required}"
# : "${JAR_PATH:?JAR_PATH is required}"

# DATABASE="${DATABASE:-POSTGRES}"
# LOG_CONFIG="${LOG_CONFIG:-file:////app/TargetAppResources/resources/log4j2.xml}"
# LOG_PATH="${LOG_PATH:-/app/log/app}"
# LOG_FILENAME="${LOG_FILENAME:-$(basename "$JAR_PATH" .jar)}"
# if [ "$DATABASE" = "MONGODB" ]; then
#   SPRING_CONFIG="file:////app/TargetAppResources/resources/mongoDB/application.properties"
# else
#   SPRING_CONFIG="file:////app/TargetAppResources/resources/postGresDB/application.properties"
# fi

# update_db_properties_if_needed() {
#   if [ "${DATABASE}" != "POSTGRES" ]; then
#     return
#   fi

#   if [ -z "${DB_HOST:-}" ] || [ -z "${DB_NAME:-}" ] || [ -z "${DB_USER:-}" ] || [ -z "${DB_PASSWORD:-}" ]; then
#     return
#   fi

#   port="${DB_PORT:-5432}"
#   jdbc_opts="${DB_JDBC_OPTIONS:-}"
#   jdbc_url="jdbc:postgresql://${DB_HOST}:${port}/${DB_NAME}"
#   # Accept both file:////app/... and file:///app/... formats.
#   config_path="${SPRING_CONFIG#file://}"

#   if [ -n "$jdbc_opts" ]; then
#     jdbc_opts="${jdbc_opts#\?}"
#     jdbc_url="${jdbc_url}?${jdbc_opts}"
#   fi

#   if [ -f "$config_path" ]; then
#     sed -i "s|^[[:space:]]*spring.data.postgre.connectionurl[[:space:]]*=.*|spring.data.postgre.connectionurl=${jdbc_url}|" "$config_path"
#     sed -i "s|^[[:space:]]*spring.data.postgre.username[[:space:]]*=.*|spring.data.postgre.username=${DB_USER}|" "$config_path"
#     sed -i "s|^[[:space:]]*spring.data.postgre.password[[:space:]]*=.*|spring.data.postgre.password=${DB_PASSWORD}|" "$config_path"
#     sed -i "s|^[[:space:]]*spring.datasource.url[[:space:]]*=.*|spring.datasource.url=${jdbc_url}|" "$config_path"
#     sed -i "s|^[[:space:]]*spring.datasource.username[[:space:]]*=.*|spring.datasource.username=${DB_USER}|" "$config_path"
#     sed -i "s|^[[:space:]]*spring.datasource.password[[:space:]]*=.*|spring.datasource.password=${DB_PASSWORD}|" "$config_path"
#   fi
# }

# if [ -x /usr/local/bin/run-config-init.sh ]; then
#   if ! /bin/sh /usr/local/bin/run-config-init.sh; then
#     echo "WARNING: run-config-init.sh failed; continuing with DB property update"
#   fi
# fi

# update_db_properties_if_needed

# exec java \
#   -Dserver.port="$SERVER_PORT" \
#   -Dlogging.config="$LOG_CONFIG" \
#   -Dlog-path="$LOG_PATH" \
#   -Dlog-filename="$LOG_FILENAME" \
#   -jar "$JAR_PATH" \
#   --spring.config.location="$SPRING_CONFIG"

#!/bin/sh
set -eu

: "${SERVER_PORT:?SERVER_PORT is required}"
: "${JAR_PATH:?JAR_PATH is required}"

DATABASE="${DATABASE:-POSTGRES}"
LOG_CONFIG="${LOG_CONFIG:-file:////app/TargetAppResources/resources/log4j2.xml}"
LOG_PATH="${LOG_PATH:-/app/log/app}"
LOG_FILENAME="${LOG_FILENAME:-$(basename "$JAR_PATH" .jar)}"
DISABLE_LOG_CONFIG="${DISABLE_LOG_CONFIG:-false}"
if [ "$DATABASE" = "MONGODB" ]; then
  SPRING_CONFIG="file:////app/TargetAppResources/resources/mongoDB/application.properties"
else
  SPRING_CONFIG="file:////app/TargetAppResources/resources/postGresDB/application.properties"
fi

update_db_properties_if_needed() {
  if [ "${DATABASE}" != "POSTGRES" ]; then
    return
  fi

  if [ -z "${DB_HOST:-}" ] || [ -z "${DB_NAME:-}" ] || [ -z "${DB_USER:-}" ] || [ -z "${DB_PASSWORD:-}" ]; then
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
    sed -i "s|^[[:space:]]*spring.data.postgre.connectionurl[[:space:]]*=.*|spring.data.postgre.connectionurl=${jdbc_url}|" "$config_path"
    sed -i "s|^[[:space:]]*spring.data.postgre.username[[:space:]]*=.*|spring.data.postgre.username=${DB_USER}|" "$config_path"
    sed -i "s|^[[:space:]]*spring.data.postgre.password[[:space:]]*=.*|spring.data.postgre.password=${DB_PASSWORD}|" "$config_path"
    sed -i "s|^[[:space:]]*spring.datasource.url[[:space:]]*=.*|spring.datasource.url=${jdbc_url}|" "$config_path"
    sed -i "s|^[[:space:]]*spring.datasource.username[[:space:]]*=.*|spring.datasource.username=${DB_USER}|" "$config_path"
    sed -i "s|^[[:space:]]*spring.datasource.password[[:space:]]*=.*|spring.datasource.password=${DB_PASSWORD}|" "$config_path"
  fi
}

if [ -x /usr/local/bin/run-config-init.sh ]; then
  if ! /bin/sh /usr/local/bin/run-config-init.sh; then
    echo "WARNING: run-config-init.sh failed; continuing with DB property update"
  fi
fi

update_db_properties_if_needed

if [ "$DISABLE_LOG_CONFIG" = "true" ]; then
  exec java \
    -Dserver.port="$SERVER_PORT" \
    -jar "$JAR_PATH" \
    --spring.config.location="$SPRING_CONFIG"
fi

exec java \
  -Dserver.port="$SERVER_PORT" \
  -Dlogging.config="$LOG_CONFIG" \
  -Dlog-path="$LOG_PATH" \
  -Dlog-filename="$LOG_FILENAME" \
  -jar "$JAR_PATH" \
  --spring.config.location="$SPRING_CONFIG"
