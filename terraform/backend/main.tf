
provider "aws" {
  version = "~> 2.36"
  region  = "ap-south-1"
}

module "backend-s3" {
  source  = "aidanmelen/backend-s3/aws"
  version = "1.0.0"
  bucket_name = "terraform-tfstate"
}