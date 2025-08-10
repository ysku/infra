variable "project" {
  type        = string
  description = "google cloud project id"
}

variable "repositories" {
  type        = list(string)
  description = "List of repositories that uses this OIDC in Github Actions"
}
