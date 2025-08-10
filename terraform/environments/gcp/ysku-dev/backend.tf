terraform {
  backend "gcs" {
    bucket = "ysku-dev-tfstates"
    prefix = "default"
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.47.0"
    }
  }
}
