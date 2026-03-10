terraform {
  backend "s3" {
    bucket  = var.backend_bucket
    key     = "terraform.tfstate"
    region  = "eu-central-1"
    encrypt = true
  }
}
