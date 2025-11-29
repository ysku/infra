terraform {
  backend "gcs" {
    bucket = "ysku-dev-tfstates"
    prefix = "shared"
  }
}
