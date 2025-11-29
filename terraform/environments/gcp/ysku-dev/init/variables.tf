variable "project_id" {
  type        = string
  description = "google cloud project id"
}

variable "repository_owner" {
  type        = string
  description = "GitHub repository owner (organization or user)"
}

variable "repositories" {
  type        = list(string)
  description = "List of repositories that uses this OIDC in Github Actions"
}
