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

resource "random_password" "database" {
  length  = 32
  special = false
}

resource "kubernetes_secret_v1" "database" {
  metadata {
    name      = "${local.application_name}-database"
    namespace = kubernetes_namespace_v1.application.metadata[0].name
    labels    = local.common_labels
  }

  data = {
    POSTGRES_DB       = "muma_bank"
    POSTGRES_USER     = "muma_bank"
    POSTGRES_PASSWORD = random_password.database.result
  }

  type = "Opaque"
}

resource "kubernetes_secret_v1" "application_database" {
  metadata {
    name      = "${local.application_name}-application-database"
    namespace = kubernetes_namespace_v1.application.metadata[0].name
    labels    = local.common_labels
  }

  data = {
    DATABASE_URL = "postgresql://muma_bank:${random_password.database.result}@${local.application_name}-postgres:5432/muma_bank"
  }

  type = "Opaque"
}

resource "kubernetes_service_v1" "database" {
  metadata {
    name      = "${local.application_name}-postgres"
    namespace = kubernetes_namespace_v1.application.metadata[0].name
    labels    = local.common_labels
  }

  spec {
    cluster_ip = "None"
    selector = {
      "app.kubernetes.io/name"      = local.application_name
      "app.kubernetes.io/instance"  = "local"
      "app.kubernetes.io/component" = "database"
    }

    port {
      name        = "postgres"
      port        = 5432
      target_port = "postgres"
      protocol    = "TCP"
    }
  }
}

resource "kubernetes_stateful_set_v1" "database" {
  metadata {
    name      = "${local.application_name}-postgres"
    namespace = kubernetes_namespace_v1.application.metadata[0].name
    labels    = merge(local.common_labels, { "app.kubernetes.io/component" = "database" })
  }

  wait_for_rollout = true

  spec {
    replicas     = 1
    service_name = kubernetes_service_v1.database.metadata[0].name

    selector {
      match_labels = {
        "app.kubernetes.io/name"      = local.application_name
        "app.kubernetes.io/instance"  = "local"
        "app.kubernetes.io/component" = "database"
      }
    }

    template {
      metadata {
        labels = merge(local.common_labels, { "app.kubernetes.io/component" = "database" })
      }

      spec {
        automount_service_account_token = false
        service_account_name            = kubernetes_service_account_v1.database.metadata[0].name

        security_context {
          run_as_non_root = true
          run_as_user     = 70
          run_as_group    = 70
          fs_group        = 70
          seccomp_profile {
            type = "RuntimeDefault"
          }
        }

        container {
          name              = "postgres"
          image             = var.postgres_image
          image_pull_policy = "IfNotPresent"

          env_from {
            secret_ref {
              name = kubernetes_secret_v1.database.metadata[0].name
            }
          }

          env {
            name  = "PGDATA"
            value = "/var/lib/postgresql/data/pgdata"
          }

          port {
            name           = "postgres"
            container_port = 5432
            protocol       = "TCP"
          }

          resources {
            requests = { cpu = "100m", memory = "128Mi" }
            limits   = { cpu = "500m", memory = "512Mi" }
          }

          security_context {
            allow_privilege_escalation = false
            read_only_root_filesystem  = true
            run_as_non_root            = true
            capabilities { drop = ["ALL"] }
          }

          startup_probe {
            exec { command = ["pg_isready", "-U", "muma_bank", "-d", "muma_bank"] }
            failure_threshold = 30
            period_seconds    = 2
          }
          readiness_probe {
            exec { command = ["pg_isready", "-U", "muma_bank", "-d", "muma_bank"] }
            failure_threshold = 3
            period_seconds    = 5
          }
          liveness_probe {
            exec { command = ["pg_isready", "-U", "muma_bank", "-d", "muma_bank"] }
            failure_threshold = 3
            period_seconds    = 10
          }

          volume_mount {
            name       = "data"
            mount_path = "/var/lib/postgresql/data"
          }
          volume_mount {
            name       = "run"
            mount_path = "/var/run/postgresql"
          }
          volume_mount {
            name       = "tmp"
            mount_path = "/tmp"
          }
        }

        volume {
          name = "run"
          empty_dir {}
        }
        volume {
          name = "tmp"
          empty_dir {}
        }
      }
    }

    volume_claim_template {
      metadata { name = "data" }
      spec {
        access_modes       = ["ReadWriteOnce"]
        storage_class_name = "standard"
        resources { requests = { storage = var.postgres_storage } }
      }
    }
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
        service_account_name            = kubernetes_service_account_v1.application.metadata[0].name

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

          env_from {
            secret_ref {
              name = kubernetes_secret_v1.application_database.metadata[0].name
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

  depends_on = [kubernetes_stateful_set_v1.database]
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
      "app.kubernetes.io/name"      = local.application_name
      "app.kubernetes.io/instance"  = "local"
      "app.kubernetes.io/component" = "api"
    }

    port {
      name        = "http"
      port        = 80
      target_port = "http"
      protocol    = "TCP"
    }
  }
}

resource "kubernetes_ingress_v1" "application" {
  metadata {
    name      = local.application_name
    namespace = kubernetes_namespace_v1.application.metadata[0].name
    labels    = local.common_labels
  }

  spec {
    ingress_class_name = "nginx"

    rule {
      host = var.ingress_host

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service_v1.application.metadata[0].name
              port {
                name = "http"
              }
            }
          }
        }
      }
    }
  }
}
