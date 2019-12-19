# Create a AWS S3 bucket that is encrypted by default
# at the server side using the name provided by the
# `bucket` variable.
resource "aws_s3_bucket" "encrypted" {
  bucket        = var.s3bucket
  force_destroy = true

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

# Set up the bucket policy to allow only a 
# specific set of operations on both the root
# of the bucket as well as its subdirectories.
resource "aws_s3_bucket_policy" "main" {
  bucket = aws_s3_bucket.encrypted.id

  policy = <<POLICY
{
    "Statement": [
        {
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:DeleteObject",
                "s3:ListMultipartUploadParts",
                "s3:AbortMultipartUpload"
            ],
            "Effect": "Allow",
            "Principal": {
                "AWS": "${aws_iam_role.main.arn}"
            },
            "Resource": "${aws_s3_bucket.encrypted.arn}/*",
            "Sid": "AddCannedAcl"
        },
        {
            "Action": [
                "s3:ListBucket",
                "s3:GetBucketLocation",
                "s3:ListBucketMultipartUploads"
            ],
            "Effect": "Allow",
            "Principal": {
                "AWS": "${aws_iam_role.main.arn}"
            },
            "Resource": "${aws_s3_bucket.encrypted.arn}"
        }
    ],
    "Version": "2012-10-17"
}
POLICY
} 

