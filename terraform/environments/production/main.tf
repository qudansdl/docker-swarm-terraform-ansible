###
# Terraform production 
##

# Do not hardcode credentials here
# Use environment variables or AWS CLI profile
provider "aws" {
  version = "~> 2.36"
  region  = "ap-south-1"
}

module "terraform-ansible-docker" {
  source = "../../modules/aws"

  environment = "production"

  swarm_vpc_cidr = "172.21.0.0/16"
  swarm_vpc_subnets = [
    "172.21.0.0/20",
    "172.21.16.0/20",
    "172.21.32.0/20"
  ]
  swarm_manager_nodes           = 1
  swarm_worker_nodes            = 2
  aws_nodes_instance_type       = "t2.large"
  s3bucket                      = "dockerregistry18122108"
  root_block_device             = [{volume_size="30",encrypted="true"}]
  ssh_pubkey_path               = "~/.ssh/id_rsa.pub"



}
