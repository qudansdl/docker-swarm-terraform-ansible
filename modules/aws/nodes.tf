# A security group for Swarm nodes
resource "aws_security_group" "swarm_node" {
  name   = "terraform-${var.environment}-swarm-node"
  vpc_id = "${aws_vpc.swarm.id}"

  # Docker Swarm ports from this security group only
  ingress {
    description = "Docker container network discovery"
    from_port   = 7946
    to_port     = 7946
    protocol    = "tcp"
    self        = true
  }
  ingress {
    description = "Docker container network discovery"
    from_port   = 7946
    to_port     = 7946
    protocol    = "udp"
    self        = true
  }
  ingress {
    description = "Docker overlay network"
    from_port   = 4789
    to_port     = 4789
    protocol    = "udp"
    self        = true
  }

  # SSH for Ansible
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = "${var.ssh_cidr_blocks}"
  }

  # Outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# A security group for Swarm manager nodes only
resource "aws_security_group" "swarm_manager_node" {
  name   = "terraform-${var.environment}-swarm-manager-node"
  vpc_id = "${aws_vpc.swarm.id}"

  # HTTP access from outside
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks = "${var.web_cidr_blocks}"
  }

  # HTTPS access from Outside
  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    cidr_blocks = "${var.web_cidr_blocks}"
  }

  # Docker Swarm manager only
  ingress {
    description     = "Docker Swarm management between managers"
    from_port       = 2377
    to_port         = 2377
    protocol        = "tcp"
    security_groups = ["${aws_security_group.swarm_node.id}"]
  }
}

# Key Pair for SSH
resource "aws_key_pair" "local" {
  key_name   = "${var.ssh_pubkey_name}-${var.environment}"
  public_key = "${file(var.ssh_pubkey_path)}"
}

## MANAGER NODES
# Spread placement group for Swarm manager nodes
resource "aws_placement_group" "swarm_manager_nodes" {
  name     = "terraform-${var.environment}-swarm-manager-nodes"
  strategy = "spread"
}

resource "aws_instance" "swarm_manager" {
  count                     = var.swarm_manager_nodes
  ami                       = "${data.aws_ami.latest-ubuntu.id}"
  instance_type             = "${var.aws_nodes_instance_type}"
  user_data                 = "${local.nodes_user_data}"
  key_name                  = "${aws_key_pair.local.id}"
  placement_group           = "${aws_placement_group.swarm_manager_nodes.id}"
  vpc_security_group_ids    = ["${aws_security_group.swarm_node.id}", "${aws_security_group.swarm_manager_node.id}"]
  dynamic "root_block_device" {
    for_each = var.root_block_device
    content {
      delete_on_termination = lookup(root_block_device.value, "delete_on_termination", null)
      encrypted             = lookup(root_block_device.value, "encrypted", null)
      iops                  = lookup(root_block_device.value, "iops", null)
      kms_key_id            = lookup(root_block_device.value, "kms_key_id", null)
      volume_size           = lookup(root_block_device.value, "volume_size", null)
      volume_type           = lookup(root_block_device.value, "volume_type", null)
    }
  }

  dynamic "ebs_block_device" {
    for_each = var.ebs_block_device
    content {
      delete_on_termination = lookup(ebs_block_device.value, "delete_on_termination", null)
      device_name           = ebs_block_device.value.device_name
      encrypted             = lookup(ebs_block_device.value, "encrypted", null)
      iops                  = lookup(ebs_block_device.value, "iops", null)
      kms_key_id            = lookup(ebs_block_device.value, "kms_key_id", null)
      snapshot_id           = lookup(ebs_block_device.value, "snapshot_id", null)
      volume_size           = lookup(ebs_block_device.value, "volume_size", null)
      volume_type           = lookup(ebs_block_device.value, "volume_type", null)
    }
  }
  tags = merge(
    {
      "Name" = var.swarm_manager_nodes > 1 || var.use_num_suffix ? format("%s-%d", var.manger_name, count.index + 1) : var.manger_name
    },
    var.tags,
  )

  volume_tags = merge(
    {
      "Name" = var.swarm_manager_nodes > 1 || var.use_num_suffix ? format("%s-%d", var.manger_name, count.index + 1) : var.manger_name
    },
    var.volume_tags,
  )
}
#Elastic IP
resource "aws_eip" "default" {
  count = var.swarm_manager_nodes
  network_interface = element(aws_instance.swarm_manager.*.primary_network_interface_id, count.index)
  vpc      = true
}


## WORKER NODES
# Spread placement group for Swarm worker nodes
resource "aws_placement_group" "swarm_worker_nodes" {
  name     = "terraform-${var.environment}-swarm-worker-nodes"
  strategy = "spread"
}



# Bootstrap script for instances
locals {
  nodes_user_data = <<EOF
#!/bin/bash
set -e
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y python-pip
	EOF
}
