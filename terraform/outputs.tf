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

output "port_forward_command" {
  description = "Command that exposes the application on host loopback port 8080."
  value       = "kubectl --namespace ${var.namespace} port-forward service/${kubernetes_service_v1.application.metadata[0].name} 8080:80"
}
