terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }

    http = {
      source = "hashicorp/http"
    }

    git = {
      source = "metio/git"
    }
  }
}
