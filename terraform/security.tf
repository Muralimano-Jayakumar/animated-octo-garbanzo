resource "kubernetes_service_account_v1" "application" {
  metadata {
    name      = local.application_name
    namespace = kubernetes_namespace_v1.application.metadata[0].name
    labels    = local.common_labels
  }

  automount_service_account_token = false
}

resource "kubernetes_service_account_v1" "database" {
  metadata {
    name      = "${local.application_name}-postgres"
    namespace = kubernetes_namespace_v1.application.metadata[0].name
    labels    = merge(local.common_labels, { "app.kubernetes.io/component" = "database" })
  }

  automount_service_account_token = false
}

resource "kubernetes_network_policy_v1" "default_deny" {
  metadata {
    name      = "default-deny-all"
    namespace = kubernetes_namespace_v1.application.metadata[0].name
    labels    = local.common_labels
  }

  spec {
    pod_selector {}
    policy_types = ["Ingress", "Egress"]
  }
}

resource "kubernetes_network_policy_v1" "application_ingress" {
  metadata {
    name      = "allow-ingress-to-application"
    namespace = kubernetes_namespace_v1.application.metadata[0].name
    labels    = local.common_labels
  }

  spec {
    pod_selector {
      match_labels = {
        "app.kubernetes.io/name"      = local.application_name
        "app.kubernetes.io/instance"  = "local"
        "app.kubernetes.io/component" = "api"
      }
    }
    policy_types = ["Ingress"]

    ingress {
      from {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = "ingress-nginx"
          }
        }
        pod_selector {
          match_labels = {
            "app.kubernetes.io/component" = "controller"
            "app.kubernetes.io/name"      = "ingress-nginx"
          }
        }
      }

      ports {
        port     = "http"
        protocol = "TCP"
      }
    }
  }
}

resource "kubernetes_network_policy_v1" "prometheus_ingress" {
  metadata {
    name      = "allow-prometheus-to-application"
    namespace = kubernetes_namespace_v1.application.metadata[0].name
    labels    = local.common_labels
  }

  spec {
    pod_selector {
      match_labels = {
        "app.kubernetes.io/name"      = local.application_name
        "app.kubernetes.io/instance"  = "local"
        "app.kubernetes.io/component" = "api"
      }
    }
    policy_types = ["Ingress"]

    ingress {
      from {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = "monitoring"
          }
        }
        pod_selector {
          match_labels = {
            "app.kubernetes.io/name" = "prometheus"
          }
        }
      }

      ports {
        port     = "http"
        protocol = "TCP"
      }
    }
  }
}

resource "kubernetes_network_policy_v1" "application_dns" {
  metadata {
    name      = "allow-application-dns"
    namespace = kubernetes_namespace_v1.application.metadata[0].name
    labels    = local.common_labels
  }

  spec {
    pod_selector {
      match_labels = {
        "app.kubernetes.io/name"      = local.application_name
        "app.kubernetes.io/instance"  = "local"
        "app.kubernetes.io/component" = "api"
      }
    }
    policy_types = ["Egress"]

    egress {
      to {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = "kube-system"
          }
        }
        pod_selector {
          match_labels = {
            "k8s-app" = "kube-dns"
          }
        }
      }

      ports {
        port     = "53"
        protocol = "UDP"
      }
      ports {
        port     = "53"
        protocol = "TCP"
      }
    }
  }
}

resource "kubernetes_network_policy_v1" "application_database" {
  metadata {
    name      = "allow-application-to-database"
    namespace = kubernetes_namespace_v1.application.metadata[0].name
    labels    = local.common_labels
  }

  spec {
    pod_selector {
      match_labels = {
        "app.kubernetes.io/name"      = local.application_name
        "app.kubernetes.io/instance"  = "local"
        "app.kubernetes.io/component" = "api"
      }
    }
    policy_types = ["Egress"]

    egress {
      to {
        pod_selector {
          match_labels = {
            "app.kubernetes.io/name"      = local.application_name
            "app.kubernetes.io/instance"  = "local"
            "app.kubernetes.io/component" = "database"
          }
        }
      }

      ports {
        port     = "postgres"
        protocol = "TCP"
      }
    }
  }
}

resource "kubernetes_network_policy_v1" "database_ingress" {
  metadata {
    name      = "allow-application-to-postgres"
    namespace = kubernetes_namespace_v1.application.metadata[0].name
    labels    = merge(local.common_labels, { "app.kubernetes.io/component" = "database" })
  }

  spec {
    pod_selector {
      match_labels = {
        "app.kubernetes.io/name"      = local.application_name
        "app.kubernetes.io/instance"  = "local"
        "app.kubernetes.io/component" = "database"
      }
    }
    policy_types = ["Ingress"]

    ingress {
      from {
        pod_selector {
          match_labels = {
            "app.kubernetes.io/name"      = local.application_name
            "app.kubernetes.io/instance"  = "local"
            "app.kubernetes.io/component" = "api"
          }
        }
      }

      ports {
        port     = "postgres"
        protocol = "TCP"
      }
    }
  }
}
