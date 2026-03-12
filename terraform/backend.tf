terraform {
  backend "s3" {
    bucket       = "fiskaly-sre-assignment-terraform-backend"
    key          = "terraform.tfstate"
    region       = "eu-central-1"
    encrypt      = true
    use_lockfile = true
  }
}