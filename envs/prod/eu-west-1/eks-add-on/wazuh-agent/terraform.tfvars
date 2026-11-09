region = "eu-west-1"

namespace    = "wazuh"
release_name = "wazuh-agent"
agent_group  = "eks-prod"

image_registry   = "495711089104.dkr.ecr.eu-west-1.amazonaws.com"
image_repository = "thirdparty/wazuh-agent"
image_tag        = "4.9.0-amd64-platform"

# Every received event is indexed into wazuh-archives-* on the manager
# (logall_json + archive indexing are on), so pod stdout logs can fill the
# 100 GB indexer volume quickly. Enable deliberately.
collect_container_logs = false
