variable "project_id" {
  type        = string
  description = "google cloud project id"
}

variable "repositories" {
  type        = list(string)
  description = "List of repositories that uses this OIDC in Github Actions"
}

variable "region" {
  type        = string
  description = "GCP region"
  default     = "asia-northeast1"
}

variable "zone" {
  type        = string
  description = "GCP zone"
  default     = "asia-northeast1-a"
}

variable "machine_type" {
  type        = string
  description = "Machine type for the compute instance"
  default     = "e2-micro"
}

