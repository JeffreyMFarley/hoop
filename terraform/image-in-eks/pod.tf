resource "kubernetes_deployment" "main" {
  metadata {
    name = var.name
    labels = {
      app = var.name
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = var.name
      }
    }

    template {
      metadata {
        labels = {
          app = var.name
        }
        # annotations = {
        #   "secrets.k8s.aws/sidecarInjectorWebhook" = "enabled"
        #   "secrets.k8s.aws/secret-arn" = var.password_arn
        # }
      }

      spec {
        container {
          image = var.repository_url
          name  = var.name
          port {
              container_port = var.app_port
          }
          env {
            name  = "POSTGRES_USER"
            value = var.db_user
          }
          env {
            name  = "POSTGRES_DB"
            value = var.db_name
          }
          env {
            name  = "POSTGRES_HOST"
            value = var.db_host
          }
          env {
            name  = "POSTGRES_PASSWORD"
            value = var.db_password
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "main" {
  metadata {
    name = var.name
    annotations = {
      "service.beta.kubernetes.io/aws-load-balancer-type" = "nlb"
    }
  }
  spec {
    selector = {
      app = kubernetes_deployment.main.metadata.0.labels.app
    }
    port {
      port = var.host_port
      target_port = var.app_port
    }
    type = "LoadBalancer"
  }
}
