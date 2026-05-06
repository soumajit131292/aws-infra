resource "helm_release" "alb_controller" {
  name       = "aws-load-balancer-controller"
  namespace  = "kube-system"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "1.7.2" 

  set {
    name  = "clusterName"
    value = var.cluster_name
  }

  set {
    name  = "region"
    value = var.region
  }

  set {
    name  = "vpcId"
    value = var.vpc_id
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = kubernetes_service_account.alb_controller.metadata[0].name
  }  

  set {
    name  = "replicaCount"
    value = "2"
  }

  set {
    name  = "enableCertManager"
    value = "false"
  }

  set {
    name  = "metricsBindAddr"
    value = "0.0.0.0:8080"
  }


  lifecycle {
    ignore_changes = [
      chart,
      repository,
    ]
  }
}
