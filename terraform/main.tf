resource "kubernetes_namespace_v1" "application" {
  metadata {
    name = var.namespace
    labels = {
      "app.kubernetes.io/part-of"                  = "muma-bank-platform"
      "app.kubernetes.io/managed-by"               = "terraform"
      "pod-security.kubernetes.io/enforce"         = "restricted"
      "pod-security.kubernetes.io/audit"           = "restricted"
      "pod-security.kubernetes.io/warn"            = "restricted"
      "pod-security.kubernetes.io/enforce-version" = "latest"
    }
  }
}

resource "kubernetes_config_map_v1" "application" {
  metadata {
    name      = "${local.application_name}-config"
    namespace = kubernetes_namespace_v1.application.metadata[0].name
    labels    = local.common_labels
  }

  data = {
    APP_ENV          = "local"
    GUNICORN_THREADS = "2"
    GUNICORN_WORKERS = "2"
    PORT             = "8080"
  }
}

resource "kubernetes_deployment_v1" "application" {
  metadata {
    name      = local.application_name
    namespace = kubernetes_namespace_v1.application.metadata[0].name
    labels    = local.common_labels
  }

  wait_for_rollout = true

  spec {
    replicas = var.replicas

    strategy {
      type = "RollingUpdate"
      rolling_update {
        max_surge       = "1"
        max_unavailable = "0"
      }
    }

    selector {
      match_labels = {
        "app.kubernetes.io/name"     = local.application_name
        "app.kubernetes.io/instance" = "local"
      }
    }

    template {
      metadata {
        labels = merge(local.common_labels, {
          "app.kubernetes.io/version" = "0.1.0"
        })
      }

      spec {
        automount_service_account_token = false

        security_context {
          run_as_non_root = true
          run_as_user     = 10001
          run_as_group    = 10001
          seccomp_profile {
            type = "RuntimeDefault"
          }
        }

        container {
          name              = local.application_name
          image             = var.image
          image_pull_policy = "Never"

          env_from {
            config_map_ref {
              name = kubernetes_config_map_v1.application.metadata[0].name
            }
          }

          port {
            name           = "http"
            container_port = 8080
            protocol       = "TCP"
          }

          resources {
            requests = {
              cpu    = "50m"
              memory = "64Mi"
            }
            limits = {
              cpu    = "250m"
              memory = "256Mi"
            }
          }

          security_context {
            allow_privilege_escalation = false
            read_only_root_filesystem  = true
            run_as_non_root            = true
            capabilities {
              drop = ["ALL"]
            }
          }

          startup_probe {
            http_get {
              path = "/healthz"
              port = "http"
            }
            failure_threshold = 30
            period_seconds    = 2
            timeout_seconds   = 1
          }

          readiness_probe {
            http_get {
              path = "/readyz"
              port = "http"
            }
            failure_threshold = 3
            period_seconds    = 5
            timeout_seconds   = 2
          }

          liveness_probe {
            http_get {
              path = "/healthz"
              port = "http"
            }
            failure_threshold = 3
            period_seconds    = 10
            timeout_seconds   = 2
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "application" {
  metadata {
    name      = local.application_name
    namespace = kubernetes_namespace_v1.application.metadata[0].name
    labels    = local.common_labels
  }

  spec {
    type = "ClusterIP"
    selector = {
      "app.kubernetes.io/name"     = local.application_name
      "app.kubernetes.io/instance" = "local"
    }

    port {
      name        = "http"
      port        = 80
      target_port = "http"
      protocol    = "TCP"
    }
  }
}
