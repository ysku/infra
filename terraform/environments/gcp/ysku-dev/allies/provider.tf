provider "google" {
  project = var.project_id
  region  = var.region
}

terraform {
  backend "gcs" {
    bucket = "ysku-dev-tfstates"
    prefix = "allies"
  }
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.47.0"
    }
  }
}
