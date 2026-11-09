##############################################################################
## Agent maintenance for ephemeral EKS nodes (applied via SSM, not user_data,
## so enabling it never stops/replaces the running instance).
##
##  0. Waits for the user_data installer (the association also runs on a
##     freshly rebuilt instance, before Wazuh is installed).
##  1. Creates the agent group the EKS DaemonSet enrolls into and gives it the
##     rootcheck signature files from the default group.
##  2. Installs a cron job that removes agents of that group which have been
##     disconnected longer than agent_cleanup_older_than. EKS nodes that are
##     scaled in or replaced never come back under the same name, so without
##     this their agents stay "disconnected" in the dashboard forever.
##
## Scoped to agent_cleanup_group only: the Zeek sensor and the manager itself
## are never removed by this job.
##
## Dry run on the server (lists what would be removed, deletes nothing):
##   sudo /usr/local/sbin/wazuh-agent-cleanup.sh --dry-run
##############################################################################

resource "aws_ssm_association" "agent_maintenance" {
  count = var.enable_agent_cleanup ? 1 : 0

  name             = "AWS-RunShellScript"
  association_name = "${var.name}-agent-maintenance"

  targets {
    key    = "InstanceIds"
    values = [aws_instance.this.id]
  }

  parameters = {
    commands = <<-EOC
      set -euo pipefail

      # --- 0. Wait for the user_data installer ------------------------------
      # On a fresh/rebuilt instance this association runs while the Wazuh
      # installer (~15-20 min) is still going; wait for the manager first.
      for _ in $(seq 1 90); do
        if [ -x /var/ossec/bin/agent_groups ] && systemctl is-active --quiet wazuh-manager; then
          break
        fi
        sleep 20
      done
      if ! systemctl is-active --quiet wazuh-manager; then
        echo "wazuh-manager not active after 30 min; giving up" >&2
        exit 1
      fi

      # --- 1. Agent group for EKS node agents -----------------------------
      if [ ! -d "/var/ossec/etc/shared/${var.agent_cleanup_group}" ]; then
        /var/ossec/bin/agent_groups -a -g "${var.agent_cleanup_group}" -q
      fi

      # New groups only get agent.conf. Agents replace their local
      # etc/shared/ with the group's files, so without these rootcheck warns
      # "No rootcheck_files file". Copy them from the default group.
      for f in rootkit_files.txt rootkit_trojans.txt; do
        if [ -f "/var/ossec/etc/shared/default/$f" ]; then
          cp -f "/var/ossec/etc/shared/default/$f" "/var/ossec/etc/shared/${var.agent_cleanup_group}/$f"
          chown wazuh:wazuh "/var/ossec/etc/shared/${var.agent_cleanup_group}/$f"
          chmod 660 "/var/ossec/etc/shared/${var.agent_cleanup_group}/$f"
        else
          echo "WARNING: /var/ossec/etc/shared/default/$f not found; rootcheck signatures not distributed" >&2
        fi
      done

      # --- 2. Cleanup script ------------------------------------------------
      cat > /usr/local/sbin/wazuh-agent-cleanup.sh <<'SCRIPT'
      #!/bin/bash
      # Remove Wazuh agents of one group that have been disconnected (or never
      # connected) for longer than OLDER_THAN. Managed by Terraform
      # (modules/wazuh-server/agent-maintenance.tf).
      set -euo pipefail

      GROUP="${var.agent_cleanup_group}"
      OLDER_THAN="${var.agent_cleanup_older_than}"
      API="https://localhost:55000"
      FILTER="agents_list=all&status=disconnected,never_connected&older_than=$OLDER_THAN&group=$GROUP"

      PW="$(tar -xOf /root/wazuh-install-files.tar wazuh-install-files/wazuh-passwords.txt \
        | grep -A1 "api_username: 'wazuh'" | grep -m1 'api_password' | sed "s/.*: '//; s/'.*//")"
      TOKEN="$(curl -sk -u "wazuh:$PW" -X POST "$API/security/user/authenticate?raw=true")"

      if [ "$${1:-}" = "--dry-run" ]; then
        curl -sk -H "Authorization: Bearer $TOKEN" \
          "$API/agents?status=disconnected,never_connected&older_than=$OLDER_THAN&group=$GROUP&select=id,name,status,lastKeepAlive&pretty=true"
        exit 0
      fi

      curl -sk -X DELETE -H "Authorization: Bearer $TOKEN" "$API/agents?$FILTER&purge=true" \
        | logger -t wazuh-agent-cleanup
      SCRIPT
      chmod 700 /usr/local/sbin/wazuh-agent-cleanup.sh

      # --- 3. Schedule ------------------------------------------------------
      echo "${var.agent_cleanup_schedule} root /usr/local/sbin/wazuh-agent-cleanup.sh" > /etc/cron.d/wazuh-agent-cleanup
      chmod 644 /etc/cron.d/wazuh-agent-cleanup
      EOC
  }
}
