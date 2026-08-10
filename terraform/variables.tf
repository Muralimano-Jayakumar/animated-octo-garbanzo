variable "kubeconfig_path" {
  description = "Path to the kubeconfig used by the Kubernetes provider."
  type        = string
  default     = "~/.kube/config"
}

variable "kubeconfig_context" {
  description = "Kubeconfig context for the local kind cluster."
  type        = string
  default     = "kind-muma-bank"
}

variable "namespace" {
  description = "Namespace for Muma Bank application resources."
  type        = string
  default     = "muma-bank"

  validation {
    condition     = can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", var.namespace))
    error_message = "The namespace must be a valid lowercase Kubernetes DNS label."
  }
}

variable "image" {
  description = "Application image preloaded into every kind node."
  type        = string
  default     = "muma-bank:dev"
}

variable "replicas" {
  description = "Application replica count; keep at one until persistent storage is implemented."
  type        = number
  default     = 1

  validation {
    condition     = var.replicas == 1
    error_message = "The in-memory application must use exactly one replica until PostgreSQL is implemented."
  }
}
