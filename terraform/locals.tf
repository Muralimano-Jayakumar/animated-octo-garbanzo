locals {
  application_name = "muma-bank"
  common_labels = {
    "app.kubernetes.io/name"       = local.application_name
    "app.kubernetes.io/instance"   = "local"
    "app.kubernetes.io/component"  = "api"
    "app.kubernetes.io/part-of"    = "muma-bank-platform"
    "app.kubernetes.io/managed-by" = "terraform"
  }
}
