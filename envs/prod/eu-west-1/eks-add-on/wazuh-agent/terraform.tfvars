region = "eu-west-1"

namespace    = "wazuh"
release_name = "wazuh-agent"
agent_group  = "eks-prod"

image_registry   = "495711089104.dkr.ecr.eu-west-1.amazonaws.com"
image_repository = "thirdparty/wazuh-agent"
image_tag        = "4.14.10-amd64-platform"

# Application pod logs only. Every received event is indexed into
# wazuh-archives-* on the manager (logall_json + archive indexing are on), so
# adding namespaces grows the 100 GB indexer volume — watch
# `df -h /var/lib/wazuh-indexer` on the server before adding more.
container_log_namespaces = ["accesshub"]

# Node sshd + sudo events from journald (AL2023 nodes have no /var/log/secure).
enable_journald = true
