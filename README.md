# Infra

Cloud Provider へのインフラ構築を行う

## Folder Structure

- `terraform/environments/<cloud provider>/<name>/{init,global,<project name>}`
  - `cloud provider` can be
    - `gcp`
  - `name` would be
    - project id in the case of google cloud
  - `project name`: name of my project ( not a project of google cloud )
