##############################################################################
## IAM policy: Wazuh dashboard viewer (SSM port-forward only)
##
## Lets a person open an SSM port-forwarding tunnel to *only* the Wazuh
## instance (so they can reach https://localhost:8443), without any VPN,
## public exposure, or SG change. This is the AWS-access layer; the person
## still needs a Wazuh dashboard login (create a read-only user in the UI).
##
## Attach this managed policy to an IAM user/group/role (see variables or
## the CLI command in the apply notes).
##############################################################################

data "aws_caller_identity" "current" {}

locals {
  wazuh_instance_arn = "arn:aws:ec2:${var.region}:${data.aws_caller_identity.current.account_id}:instance/${module.wazuh.instance_id}"
}

resource "aws_iam_policy" "wazuh_dashboard_viewer" {
  name        = "prod-wazuh-dashboard-viewer"
  description = "SSM port-forward to the prod Wazuh dashboard instance only"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "StartPortForwardToWazuhInstance"
        Effect   = "Allow"
        Action   = "ssm:StartSession"
        Resource = local.wazuh_instance_arn
        Condition = {
          BoolIfExists = { "ssm:SessionDocumentAccessCheck" = "true" }
        }
      },
      {
        Sid      = "AllowPortForwardDocumentOnly"
        Effect   = "Allow"
        Action   = "ssm:StartSession"
        Resource = "arn:aws:ssm:${var.region}::document/AWS-StartPortForwardingSession"
      },
      {
        Sid      = "ManageOwnSession"
        Effect   = "Allow"
        Action   = ["ssm:TerminateSession", "ssm:ResumeSession"]
        Resource = "arn:aws:ssm:*:*:session/$${aws:username}-*"
      }
    ]
  })

  tags = var.tags
}

# Optional: attach directly to existing IAM users (must already exist).
resource "aws_iam_user_policy_attachment" "viewers" {
  for_each   = toset(var.dashboard_viewer_iam_user_names)
  user       = each.value
  policy_arn = aws_iam_policy.wazuh_dashboard_viewer.arn
}

# Optional: attach to existing IAM groups (must already exist).
resource "aws_iam_group_policy_attachment" "viewer_groups" {
  for_each   = toset(var.dashboard_viewer_iam_group_names)
  group      = each.value
  policy_arn = aws_iam_policy.wazuh_dashboard_viewer.arn
}

variable "dashboard_viewer_iam_user_names" {
  description = "Existing IAM usernames to attach the Wazuh dashboard-viewer policy to. Empty = create the policy only, attach manually later."
  type        = list(string)
  default     = []
}

variable "dashboard_viewer_iam_group_names" {
  description = "Existing IAM group names to attach the Wazuh dashboard-viewer policy to."
  type        = list(string)
  default     = []
}

output "dashboard_viewer_policy_arn" {
  description = "ARN of the Wazuh dashboard-viewer IAM policy (attach to users/roles/groups)."
  value       = aws_iam_policy.wazuh_dashboard_viewer.arn
}
