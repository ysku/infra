provider "google" {
  project = var.project_id
}

provider "google-beta" {
  project = var.project_id
}

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.14.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 7.14.0"
    }
  }
}
