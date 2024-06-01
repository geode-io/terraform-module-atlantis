variable "name" {
  type        = string
  description = "Atlantis instance name"
}

variable "image_name" {
  type        = string
  description = "Full image repo/name"
  default     = "ghcr.io/runatlantis/atlantis"
}

variable "image_tag" {
  type        = string
  description = "Image version tag"
  default     = "v0.27.3"
}

variable "dns_name" {
  type        = string
  description = "Name to use for the DNS record if different from the name"
  default     = null
}

variable "route53_zone_name" {
  type        = string
  description = "Route53 zone name"
}

variable "acm_certificate_key_algorithm" {
  type        = string
  description = "Key algorithm for the ACM certificate"
  default     = "EC_prime256v1"
}

variable "acm_certificate_arn" {
  type        = string
  description = "ARN of an existing ACM certificate"
  default     = null
}

variable "vpc_id" {
  type = string
}

variable "lb_ip_address_type" {
  type        = string
  description = "IP address type for the load balancer"
  default     = "ipv4"
}

variable "lb_subnet_ids" {
  type        = list(string)
  description = "Subnet IDs for the load balancer"
  validation {
    condition     = length(var.lb_subnet_ids) >= 2
    error_message = "At least two subnet IDs must be provided"
  }
}

variable "create_ecs_cluster" {
  type        = bool
  description = "Create an ECS cluster for this deployment"
  default     = true
}

variable "ecs_cluster_name" {
  type        = string
  description = "Name of the ECS cluster to create"
  default     = null
}

variable "task_subnet_ids" {
  type        = list(string)
  description = "Subnet IDs for the task"
  validation {
    condition     = length(var.task_subnet_ids) >= 2
    error_message = "At least two subnet IDs must be provided"
  }
}

variable "task_desired_count" {
  type        = number
  description = "Number of Atlantis tasks to run"
  default     = 2
}

variable "task_cpu" {
  type        = number
  default     = 512
  description = "CPU units for the Atlantis task"
}

variable "task_memory" {
  type        = number
  default     = 1024
  description = "Memory for the Atlantis task in MiB"
}

variable "efs_kms_key_id" {
  type        = string
  description = "KMS key ID for EFS encryption. If not provided, the default EFS key will be used."
  default     = null
}

variable "repo_allowlist" {
  type        = list(string)
  description = "List of allowed repository patterns"
}

variable "github_app_slug" {
  type        = string
  description = "GitHub App slug"
}

variable "github_app_id" {
  type        = number
  description = "GitHub App ID"
}

variable "github_app_private_key" {
  type        = string
  description = "GitHub App private key"
}

variable "github_webhook_secret" {
  type        = string
  description = "GitHub webhook secret"
}

variable "oidc_authorization_endpoint" {
  type        = string
  description = "OIDC authorization endpoint"
}

variable "oidc_client_id" {
  type        = string
  description = "OIDC client ID"
}

variable "oidc_client_secret" {
  type        = string
  description = "OIDC client secret"
}

variable "oidc_issuer" {
  type        = string
  description = "OIDC issuer"
}

variable "oidc_token_endpoint" {
  type        = string
  description = "OIDC token endpoint"
}

variable "oidc_user_info_endpoint" {
  type        = string
  description = "OIDC user info endpoint"
}

variable "oidc_session_timeout_seconds" {
  type        = number
  description = "OIDC session timeout in seconds"
  default     = 86400
}
