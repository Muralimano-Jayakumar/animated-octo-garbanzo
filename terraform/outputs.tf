output "kubernetes_version" {
  description = "Kubernetes server version reported by the provider."
  value       = data.kubernetes_server_version.current.version
}

output "namespace" {
  description = "Namespace containing the application resources."
  value       = kubernetes_namespace_v1.application.metadata[0].name
}

output "service_name" {
  description = "ClusterIP Service name."
  value       = kubernetes_service_v1.application.metadata[0].name
}

output "database_service_name" {
  description = "Headless Service used to discover PostgreSQL."
  value       = kubernetes_service_v1.database.metadata[0].name
}

output "database_persistent_volume_claim" {
  description = "PersistentVolumeClaim created for the PostgreSQL replica."
  value       = "data-${kubernetes_stateful_set_v1.database.metadata[0].name}-0"
}

output "port_forward_command" {
  description = "Command that exposes the application on host loopback port 8080."
  value       = "kubectl --namespace ${var.namespace} port-forward service/${kubernetes_service_v1.application.metadata[0].name} 8080:80"
}

output "ingress_url" {
  description = "Loopback-only URL exposed through ingress-nginx and kind."
  value       = "http://${var.ingress_host}:8081"
}
