flowchart LR
U[Users / Internet] --> ALB_DNS[ALB DNS Name\n*.us-east-1.elb.amazonaws.com]

subgraph AWS["AWS us-east-1"]
subgraph VPC["VPC dev-vpc (10.10.0.0/16)"]

subgraph PUB["Public Subnets"]
ALB[Public ALB Ingress\n(internet-facing, 80/443)]
NAT[NAT Gateways]
IGW[Internet Gateway]
end

subgraph APP["Private App Subnets"]
EKS[EKS Cluster\ndev-accesshub-cluster]
NG[Managed Node Group core-ng\nm6i.large, maxPods=110]
ALBC[AWS Load Balancer Controller]
SVC[K8s Ingress Paths → Services\n/accesshub /pgmodule /authcontroller ...]
end

subgraph DB["Private DB Subnets"]
AUR[Aurora PostgreSQL Cluster\ndev-aurora-postgres]
end

subgraph FW["Firewall Subnets"]
NFW[AWS Network Firewall]
end

VPCE[VPC Endpoints\n(EKS, STS, ECR, Logs, SSM, KMS, RDS, S3)]

end
end

ALB_DNS --> ALB
ALB --> NG
NG --> SVC

ALBC --> ALB
EKS --> NG

NG -->|5432| AUR
NG --> VPCE

NG -->|0.0.0.0/0| NFW
NFW --> NAT
NAT --> IGW
IGW --> U