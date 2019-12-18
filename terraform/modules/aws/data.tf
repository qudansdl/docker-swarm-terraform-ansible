# Available AZs in the current region
data "aws_availability_zones" "available" {}

# Latest Ubuntu 18.04 LTS AMI in the current region
data "aws_ami" "latest-ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# The bucket-root policy defines the API actions that are
# allowed to take place on the bucket root directory.
#
# Given that by default nothing is allowed, here we list
# the actions that are meant to be allowed.

data "aws_iam_policy_document" "bucket-root" {
  statement {
    effect = "Allow"

    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation",
      "s3:ListBucketMultipartUploads",
    ]

    resources = [
      "arn:aws:s3:::var.s3bucket",
    ]
  }
}

# The bucket-subdirs policy defines the API actions that
# are allowed to take place on the bucket subdirectories.

data "aws_iam_policy_document" "bucket-subdirs" {
  statement {
    effect = "Allow"

    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:ListMultipartUploadParts",
      "s3:AbortMultipartUpload",
    ]

    resources = [
      "arn:aws:s3:::var.s3bucket/*",
    ]
  }
}

#Here we allow the instance to use the AWS Security Token Service
# (STS) AssumeRole action as that's the action that's going to
# give the instance the temporary security credentials needed
# to sign the API requests made by that instance.

data "aws_iam_policy_document" "default" {
  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type = "Service"

      identifiers = [
        "ec2.amazonaws.com",
      ]
    }
  }
}