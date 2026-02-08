locals {
  firewall_endpoint_by_az = {
    for s in tolist(aws_networkfirewall_firewall.this.firewall_status[0].sync_states) :
    s.availability_zone => s.attachment[0].endpoint_id
  }
}

###############################
##       VPC & IGW           ##
###############################
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.tags, { Name = var.name })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
}

###############################
##       Subnets             ##
###############################
resource "aws_subnet" "public" {
  for_each = var.public_subnets

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value
  availability_zone       = var.azs[index(keys(var.public_subnets), each.key)]
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name                        = "public-${each.key}"
    "kubernetes.io/role/elb"    = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"

  })
}

resource "aws_subnet" "private_app" {
  for_each = var.private_app_subnets

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value
  availability_zone = var.azs[index(keys(var.private_app_subnets), each.key)]

  tags = merge(var.tags, {
    Name                                = "private-app-${each.key}"
    "kubernetes.io/role/internal-elb"   = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  })
}

resource "aws_subnet" "private_db" {
  for_each = var.private_db_subnets

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value
  availability_zone = var.azs[index(keys(var.private_db_subnets), each.key)]

  tags = merge(var.tags, {
    Name = "private-db-${each.key}"
  })
}

###############################
##       NAT Gateway (per AZ) 
###############################
resource "aws_eip" "nat" {
  for_each = aws_subnet.public
  domain   = "vpc"
}

resource "aws_nat_gateway" "this" {
  for_each      = aws_subnet.public
  subnet_id     = each.value.id
  allocation_id = aws_eip.nat[each.key].id
}

###############################
## Route Tables – Public (per AZ)
###############################
resource "aws_route_table" "public" {
  for_each = aws_subnet.public
  vpc_id  = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "public-rt-${each.key}"
  })
}

resource "aws_route" "public_igw" {
  for_each = aws_route_table.public

  route_table_id         = each.value.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public[each.key].id
}

###############################
## Route Tables – Private APP (per AZ)
###############################
resource "aws_route_table" "private_app" {
  for_each = aws_subnet.private_app
  vpc_id  = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "private-app-rt-${each.key}"
  })
}

resource "aws_route_table_association" "private_app" {
  for_each = aws_subnet.private_app

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private_app[each.key].id
}

###############################
## Route Tables – Private DB (NO internet)
###############################
resource "aws_route_table" "private_db" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "private-db-rt"
  })
}

resource "aws_route_table_association" "private_db" {
  for_each = aws_subnet.private_db

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private_db.id
}

###############################
## Stateless+ Stateful Rule Group
###############################
# resource "aws_networkfirewall_rule_group" "stateless" {
#   name     = "${var.name}-stateless"
#   capacity = 100
#   type     = "STATELESS"

#   rule_group {
#     rules_source {
#       stateless_rules_and_custom_actions {
#         stateless_rule {
#           priority = 1
#           rule_definition {
#             actions = ["aws:forward_to_sfe"]
#             match_attributes {
#               protocols = [6, 17]
#               source {
#                 address_definition = "0.0.0.0/0"
#               }
#               destination {
#                 address_definition = "0.0.0.0/0"
#               }
#             }
#           }
#         }
#       }
#     }
#   }
# }

resource "aws_networkfirewall_rule_group" "stateless" {
  name     = "${var.name}-stateless"
  capacity = 100
  type     = "STATELESS"

  rule_group {
    rules_source {
      stateless_rules_and_custom_actions {

        # ✅ DNS UDP
        stateless_rule {
          priority = 1
          rule_definition {
            actions = ["aws:pass"]
            match_attributes {
              protocols = [17]

              destination_port {
                from_port = 53
                to_port   = 53
              }

              source {
                address_definition = "0.0.0.0/0"
              }

              destination {
                address_definition = "0.0.0.0/0"
              }
            }
          }
        }

        # ✅ DNS TCP
        stateless_rule {
          priority = 2
          rule_definition {
            actions = ["aws:pass"]
            match_attributes {
              protocols = [6]

              destination_port {
                from_port = 53
                to_port   = 53
              }

              source {
                address_definition = "0.0.0.0/0"
              }

              destination {
                address_definition = "0.0.0.0/0"
              }
            }
          }
        }

        # 🔁 Everything else → stateful engine
        stateless_rule {
          priority = 100
          rule_definition {
            actions = ["aws:forward_to_sfe"]
            match_attributes {
              protocols = [6, 17]

              source {
                address_definition = "0.0.0.0/0"
              }

              destination {
                address_definition = "0.0.0.0/0"
              }
            }
          }
        }
      }
    }
  }
}




###############################
## Firewall Policy
###############################
resource "aws_networkfirewall_firewall_policy" "this" {
  name = "${var.name}-fw-policy"

  firewall_policy {
    stateless_default_actions          = ["aws:drop"]
    stateless_fragment_default_actions = ["aws:forward_to_sfe"]

    stateless_rule_group_reference {
      priority     = 10
      resource_arn = aws_networkfirewall_rule_group.stateless.arn
    }

    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.stateful.arn
    }
  }
}

###############################
## Rule Group
###############################
resource "aws_network_acl_association" "private_app" {
  for_each       = aws_subnet.private_app
  subnet_id      = each.value.id
  network_acl_id = aws_network_acl.private_app.id
}
resource "aws_network_acl_rule" "app_in_ephemeral" {
  network_acl_id = aws_network_acl.private_app.id
  rule_number    = 120
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}
resource "aws_network_acl_rule" "app_out_ephemeral" {
  network_acl_id = aws_network_acl.private_app.id
  rule_number    = 120
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}
resource "aws_network_acl_rule" "app_out_ntp" {
  network_acl_id = aws_network_acl.private_app.id
  rule_number    = 130
  egress         = true
  protocol       = "udp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 123
  to_port        = 123
}
resource "aws_network_acl_association" "private_db" {
  for_each       = aws_subnet.private_db
  subnet_id      = each.value.id
  network_acl_id = aws_network_acl.private_db.id
}
resource "aws_network_acl_rule" "db_in_ephemeral" {
  network_acl_id = aws_network_acl.private_db.id
  rule_number    = 120
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr
  from_port      = 1024
  to_port        = 65535
}
resource "aws_network_acl_rule" "db_out_ephemeral" {
  network_acl_id = aws_network_acl.private_db.id
  rule_number    = 120
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr
  from_port      = 1024
  to_port        = 65535
}




###############################
## Firewall
###############################

resource "aws_networkfirewall_firewall" "this" {
  name                = "${var.name}-fw"
  vpc_id              = aws_vpc.this.id
  firewall_policy_arn = aws_networkfirewall_firewall_policy.this.arn

  dynamic "subnet_mapping" {
    for_each = aws_subnet.firewall
    content {
      subnet_id = subnet_mapping.value.id
    }
  }
  lifecycle {
      ignore_changes = [
        subnet_mapping
      ]
  }

}
resource "aws_route_table" "firewall" {
  for_each = aws_subnet.firewall
  vpc_id   = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "firewall-rt-${each.key}"
  })
}
resource "aws_route_table_association" "firewall" {
  for_each = aws_subnet.firewall

  subnet_id      = each.value.id
  route_table_id = aws_route_table.firewall[each.key].id
  # replace_existing_association = true
}

###############################
## Private → Firewall → NAT
###############################
resource "aws_route" "private_to_fw" {
  for_each = aws_subnet.private_app

  route_table_id         = aws_route_table.private_app[each.key].id
  destination_cidr_block = "0.0.0.0/0"

  vpc_endpoint_id = local.firewall_endpoint_by_az[each.value.availability_zone]
}


resource "aws_route" "fw_to_nat" {
  for_each = aws_route_table.firewall

  route_table_id         = each.value.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[each.key].id
}

resource "aws_subnet" "firewall" {
  for_each = var.firewall_subnets

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value
  availability_zone = var.azs[index(keys(var.firewall_subnets), each.key)]

  tags = merge(var.tags, {
    Name = "firewall-${each.key}"
  })
}


resource "aws_security_group" "public_test" {
  name   = "${var.name}-public-test-sg"
  vpc_id = aws_vpc.this.id

  ingress {
    description = "SSH from local machine"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["49.207.193.197/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name}-public-test-sg"
  })
}


###############################
## VPC Flow Logs
###############################
resource "aws_cloudwatch_log_group" "vpc_flow" {
  name              = "/aws/vpc/${var.name}-flowlogs"
  retention_in_days = 90
}
resource "aws_cloudwatch_log_group" "firewall" {
  name              = "/aws/network-firewall/${var.name}"
  retention_in_days = 90

  tags = var.tags
}

resource "aws_iam_role" "flow_logs" {
  name = "${var.name}-vpc-flowlogs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "vpc-flow-logs.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "flow_logs" {
  role = aws_iam_role.flow_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
      Resource = "*"
    }]
  })
}

resource "aws_flow_log" "this" {
  vpc_id          = aws_vpc.this.id
  traffic_type    = "ALL"
  log_destination = aws_cloudwatch_log_group.vpc_flow.arn
  iam_role_arn    = aws_iam_role.flow_logs.arn
}

resource "aws_networkfirewall_logging_configuration" "this" {
  depends_on = [
    aws_cloudwatch_log_group.firewall
  ]
  firewall_arn = aws_networkfirewall_firewall.this.arn

  logging_configuration {
    log_destination_config {
      log_destination = {
        logGroup = aws_cloudwatch_log_group.firewall.name
      }
      log_destination_type = "CloudWatchLogs"
      log_type             = "FLOW"
    }

    log_destination_config {
      log_destination = {
        logGroup = aws_cloudwatch_log_group.firewall.name
      }
      log_destination_type = "CloudWatchLogs"
      log_type             = "ALERT"
    }
  }
}


## NACL
resource "aws_network_acl" "private_app" {
  vpc_id = aws_vpc.this.id
}

resource "aws_network_acl_rule" "app_in_vpc" {
  network_acl_id = aws_network_acl.private_app.id
  rule_number    = 100
  egress         = false
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr
}

resource "aws_network_acl_rule" "app_out_https" {
  network_acl_id = aws_network_acl.private_app.id
  rule_number    = 100
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

resource "aws_network_acl_rule" "app_out_dns" {
  network_acl_id = aws_network_acl.private_app.id
  rule_number    = 110
  egress         = true
  protocol       = "udp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 53
  to_port        = 53
}

resource "aws_network_acl" "private_db" {
  vpc_id = aws_vpc.this.id
}

resource "aws_network_acl_rule" "db_in" {
  for_each = var.private_app_subnets

  network_acl_id = aws_network_acl.private_db.id
  rule_number    = 100 + index(keys(var.private_app_subnets), each.key)
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = each.value
  from_port      = 5432
  to_port        = 5432
}
resource "aws_security_group" "app" {
  name   = "${var.name}-app-sg"
  vpc_id = aws_vpc.this.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "db" {
  name   = "${var.name}-db-sg"
  vpc_id = aws_vpc.this.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }
}

resource "aws_networkfirewall_rule_group" "stateful" {
  name     = "${var.name}-stateful"
  capacity = 100
  type     = "STATEFUL"

  rule_group {
    rules_source {
      rules_string = <<EOF
pass tcp any any -> any 443 (sid:1;)
pass udp any any -> any 53  (sid:2;)
pass tcp any any -> any 53  (sid:3;)
pass udp any any -> any 123 (sid:4;)
pass tcp any any -> any 10250 (sid:5;)
EOF
    }
  }
}


### SSM Instance Profile for EC2 instances to allow SSM access without needing public IPs or bastion hosts
resource "aws_iam_role" "ec2_ssm" {
  name = "${var.name}-ec2-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ec2_ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
resource "aws_iam_instance_profile" "ec2_ssm" {
  name = "${var.name}-ec2-ssm-profile"
  role = aws_iam_role.ec2_ssm.name
}

### Interface Endpoints
locals {
  eks_endpoints = [
    "eks",
    "sts",
    "ec2",
    "ecr.api",
    "ecr.dkr",
    "logs",
    "monitoring",
    "ec2messages",
    "ssmmessages",
    "ssm",
    "kms",
    "secretsmanager",
    "rds"
  ]
}


resource "aws_vpc_endpoint" "eks_if" {
  for_each = toset(local.eks_endpoints)

  vpc_id              = aws_vpc.this.id
  service_name        = "com.amazonaws.${var.region}.${each.key}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = values(aws_subnet.private_app)[*].id
  # security_group_ids  = [aws_security_group.app.id]
  security_group_ids = [aws_security_group.vpce.id]

  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [
    for rt in aws_route_table.private_app : rt.id
  ]
}


## VPC Endpoints for Network Firewall
resource "aws_security_group" "vpce" {
  name   = "${var.name}-vpce-sg"
  vpc_id = aws_vpc.this.id

  ingress {
    description = "Allow HTTPS from VPC to interface endpoints"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name}-vpce-sg"
  })
}

resource "aws_network_acl_rule" "app_in_all_vpc" {
  network_acl_id = aws_network_acl.private_app.id
  rule_number    = 90
  egress         = false
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr
}

resource "aws_route" "fw_to_vpc" {
  for_each = aws_route_table.firewall

  route_table_id         = each.value.id
  destination_cidr_block = var.vpc_cidr
  gateway_id             = "local"
}