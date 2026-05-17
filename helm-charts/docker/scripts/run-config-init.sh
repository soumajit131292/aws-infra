#!/bin/sh
set -eu

mode="${1:-all}"
if [ "${CONFIG_INIT_MODE:-}" = "tenant" ]; then
  mode="tenant"
fi
debug_enabled="${CONFIG_INIT_DEBUG:-false}"

base_url="${ACCESSHUB_BASE_URL:-${HOST_NAME:-}}"
tenant_id="${TENANT_ID:-}"
native_superadmin_id="${NATIVE_SUPERADMINID:-}"
native_superadmin_pwd="${NATIVE_SUPERADMIN_PWD:-}"
grc_api_access_user="${GRC_API_ACCESS_USER:-}"
grc_api_access_pwd="${GRC_API_ACCESS_PWD:-}"

if [ -n "$base_url" ]; then
  domain_name="${base_url#*://}"
  domain_name="${domain_name%%/*}"
else
  domain_name=""
fi

replace_prop() {
  file="$1"
  key="$2"
  value="$3"
  sed -i "s|^[[:space:]]*${key}[[:space:]]*=.*|${key}=${value}|" "$file"
}

escape_sed_replacement() {
  # Escape characters that are special in sed replacement section.
  printf '%s' "$1" | sed 's/[&|\\]/\\&/g'
}

is_debug() {
  [ "$debug_enabled" = "true" ] || [ "$debug_enabled" = "1" ] || [ "$debug_enabled" = "yes" ]
}

print_debug() {
  if is_debug; then
    echo "$1"
  fi
}

require_tenant_inputs() {
  if [ "$mode" = "tenant" ] || [ "$mode" = "--tenant-only" ]; then
    missing=""
    [ -n "$base_url" ] || missing="${missing} ACCESSHUB_BASE_URL"
    [ -n "$tenant_id" ] || missing="${missing} TENANT_ID"
    [ -n "$native_superadmin_id" ] || missing="${missing} NATIVE_SUPERADMINID"
    [ -n "$native_superadmin_pwd" ] || missing="${missing} NATIVE_SUPERADMIN_PWD"
    if [ -n "$missing" ]; then
      echo "ERROR: missing required tenant bootstrap env vars:${missing}"
      exit 1
    fi
  fi
}

update_base_properties() {
  if [ -z "$base_url" ]; then
    return
  fi

  allservices="/app/TargetAppResources/resources/allServices.properties"
  if [ -f "$allservices" ]; then
    replace_prop "$allservices" "SCHEDULEJOB_SERVICE_URL" "$base_url/scheduler/scheduler"
    replace_prop "$allservices" "SCHEDULEJOB_CONTROLLER_SERVICE_URL" "$base_url/jobcontroller"
    replace_prop "$allservices" "SEND_MAIL_SERVICE" "$base_url/notification/jersey/email/sendemail"
    replace_prop "$allservices" "EMAILTEMPLATE_SERVICE_URL" "$base_url/notification/jersey/email/createnewtemplate"
    replace_prop "$allservices" "SMTP_SERVICE_URL" "$base_url/notification/jersey/email/createnewsmtp"
    replace_prop "$allservices" "CAMPAIGN_CONTROLLER_SERVICE_URL" "$base_url/campaign"
    replace_prop "$allservices" "IDENTITY_VIEWER_SERVICE_URL" "$base_url/IdentityViewer/jersey/IdentityViewer"
    replace_prop "$allservices" "PROVISIONING_AGENT_SERIVCE_URL" "$base_url/agentService"
    replace_prop "$allservices" "PROVISIONING_GATEWAY_SERVICE_URL" "$base_url/scim/v2"
    replace_prop "$allservices" "APPLICATION_REGISTRATION_SERVICE_URL" "$base_url/registerscimapp"
    replace_prop "$allservices" "ENTERPRISE_CUSTOM_ATTRIBUTE_SERVICE_URL" "$base_url/scimattribute"
    replace_prop "$allservices" "SERVICENOW_WRAPPER_SERIVCE_URL" "$base_url/servicenow/api/v1"
    replace_prop "$allservices" "ITASSETS_DISCOVERY_SERIVCE_URL" "$base_url/itasset"
    replace_prop "$allservices" "SCHEMA_SERVICE_URL" "$base_url/schemamapper"
    replace_prop "$allservices" "IV_APPLICATION_REGISTRATION_SERVICE_URL" "$base_url/registerivapp"
    replace_prop "$allservices" "IDENTITYVIEWER_ASSETS_DISCOVERY_SERIVCE_URL" "$base_url/ivfile"
    replace_prop "$allservices" "SCIM_PERSIST_SERVICE_URL" "$base_url/scim-application"
  fi

  jwt_config="/app/TargetAppResources/resources/JWTConfig.properties"
  if [ -f "$jwt_config" ]; then
    replace_prop "$jwt_config" "OAUTH_BROKER_URL" "$base_url/RequestJWTToken"
    replace_prop "$jwt_config" "CERTIFICATION_APP_URL" "$base_url/iga"
    if [ -n "$domain_name" ]; then
      replace_prop "$jwt_config" "CERTIFICATION_DOMAIN" "$domain_name"
    fi
    replace_prop "$jwt_config" "NATIVEUSER_SERVICES" "$base_url/nativeusers"
  fi

  scim_config="/app/TargetAppResources/resources/scimConfig.properties"
  if [ -f "$scim_config" ]; then
    replace_prop "$scim_config" "PROVISIONING_AGENT_SERIVCE_URL" "$base_url/agentService"
  fi

  app_reg_config="/app/TargetAppResources/resources/ApplicationRegistration/config.properties"
  if [ -f "$app_reg_config" ]; then
    replace_prop "$app_reg_config" "SCIMURL" "$base_url/scim/v2"
    replace_prop "$app_reg_config" "TOKEN_PROVIDER_URL" "$base_url/RequestJWTToken/TokenProvider"
    replace_prop "$app_reg_config" "MONGOSERVICEURL" "$base_url/appRegMongoService/api/v1"
    replace_prop "$app_reg_config" "IVURL" "$base_url/ifactory/v2"
    if [ -n "$grc_api_access_user" ]; then
      replace_prop "$app_reg_config" "GRC_API_ACCESS_USER" "$grc_api_access_user"
    fi
    if [ -n "$grc_api_access_pwd" ]; then
      replace_prop "$app_reg_config" "GRC_API_ACCESS_PWD" "$grc_api_access_pwd"
    fi
  fi

  oauth_details="/app/TargetAppResources/resources/oauthDetails.properties"
  if [ -f "$oauth_details" ]; then
    replace_prop "$oauth_details" "OAUTH_ENDPOINT_URL" "$base_url/registeredapp"
    replace_prop "$oauth_details" "IVOAUTH_ENDPOINT_URL" "$base_url/ivregisteredapp"
  fi

  app_mapping="/app/TargetAppResources/resources/AppMapping.properties"
  if [ -f "$app_mapping" ]; then
    replace_prop "$app_mapping" "HOST_URL" "$base_url/registerscimapp"
    replace_prop "$app_mapping" "IV_HOST_URL" "$base_url/registerivapp"
  fi

  ui_config="/app/apache-tomcat-9.0.97/webapps/accesshub/config.json"
  if [ -f "$ui_config" ] && [ -n "$domain_name" ]; then
    sed -i "s|\"GATEWAY_SERVICES_HOSTNAME\": *\"[^\"]*\"|\"GATEWAY_SERVICES_HOSTNAME\": \"$domain_name\"|" "$ui_config"
  fi
}

update_tenant_setup_script() {
  tenant_script="/app/Accesshub_Files/Install_Scripts/tenantsetup.sh"
  if [ ! -f "$tenant_script" ]; then
    print_debug "CONFIG_INIT_DEBUG: tenant script not found at $tenant_script"
    return
  fi

  print_debug "CONFIG_INIT_DEBUG: mode=$mode"
  print_debug "CONFIG_INIT_DEBUG: tenant_script=$tenant_script"
  print_debug "CONFIG_INIT_DEBUG: base_url=${base_url:-<empty>} tenant_id=${tenant_id:-<empty>} native_superadmin_id=${native_superadmin_id:-<empty>} native_superadmin_pwd_set=$([ -n "${native_superadmin_pwd:-}" ] && echo yes || echo no)"
  if is_debug; then
    echo "CONFIG_INIT_DEBUG: before substitution (first 12 matching lines)"
    grep -nE "https?://|/authcontroller/|/uiprivilege/api/v1/|/privilegedrole/api/v1/|tenantId|NATIVE_SUPERADMINID|NATIVE_SUPERADMIN_PWD" "$tenant_script" | head -12 || true
  fi

  if [ -n "$base_url" ]; then
    sed -i "s|https://[^/']*|$base_url|g" "$tenant_script"
  fi
  if [ -n "$tenant_id" ]; then
    tenant_id_escaped="$(escape_sed_replacement "$tenant_id")"
    sed -i "s|\(/authcontroller/\)[^/]*\(/loginconfig\)|\1$tenant_id\2|g" "$tenant_script"
    sed -i "s|\(/uiprivilege/api/v1/\)[^/]*\(/privilege\)|\1$tenant_id\2|g" "$tenant_script"
    sed -i "s|\(/privilegedrole/api/v1/\)[^/]*\(/alladminroles\)|\1$tenant_id\2|g" "$tenant_script"
    sed -i "s|\(/privilegedrole/api/v1/\)[^/]*\(/roleprivilege\)|\1$tenant_id\2|g" "$tenant_script"
    sed -i "s|\"tenantId\"[[:space:]]*:[[:space:]]*\"[^\"]*\"|\"tenantId\":\"$tenant_id_escaped\"|g" "$tenant_script"
  fi
  if [ -n "$native_superadmin_id" ]; then
    native_superadmin_id_escaped="$(escape_sed_replacement "$native_superadmin_id")"
    sed -i "s|\"NATIVE_SUPERADMINID\"[[:space:]]*:[[:space:]]*\"[^\"]*\"|\"NATIVE_SUPERADMINID\":\"$native_superadmin_id_escaped\"|g" "$tenant_script"
  fi
  if [ -n "$native_superadmin_pwd" ]; then
    native_superadmin_pwd_escaped="$(escape_sed_replacement "$native_superadmin_pwd")"
    sed -i "s|\"NATIVE_SUPERADMIN_PWD\"[[:space:]]*:[[:space:]]*\"[^\"]*\"|\"NATIVE_SUPERADMIN_PWD\":\"$native_superadmin_pwd_escaped\"|g" "$tenant_script"
  fi

  if is_debug; then
    echo "CONFIG_INIT_DEBUG: after substitution (first 12 matching lines)"
    grep -nE "https?://|/authcontroller/|/uiprivilege/api/v1/|/privilegedrole/api/v1/|tenantId|NATIVE_SUPERADMINID|NATIVE_SUPERADMIN_PWD" "$tenant_script" | head -12 || true
    echo "CONFIG_INIT_DEBUG: substitution complete"
  fi
}

case "$mode" in
  tenant|--tenant-only)
    require_tenant_inputs
    update_tenant_setup_script
    ;;
  all|"")
    update_base_properties
    update_tenant_setup_script
    ;;
  *)
    update_base_properties
    update_tenant_setup_script
    ;;
esac
