terraform {
  required_version = "1.9.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.67.0"
    }
  }
}

provider "aws" {
  region = var.region

  access_key = var.access_key
  secret_key = var.secret_key
}

resource "random_pet" "website" {
  length = 4
}

resource "aws_s3_bucket" "website" {
  bucket = "${terraform.workspace}-${random_pet.website.id}-fsl-website"

  tags = {
    Name        = "${terraform.workspace}-${random_pet.website.id}-fsl-website"
    Environment = terraform.workspace
  }
}

resource "aws_s3_bucket_public_access_block" "website" {
  bucket = aws_s3_bucket.website.id


  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_ownership_controls" "website" {
  bucket = aws_s3_bucket.website.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "website" {
  depends_on = [
    aws_s3_bucket_ownership_controls.website,
    aws_s3_bucket_public_access_block.website
  ]

  bucket = aws_s3_bucket.website.id

  acl = "public-read"
}


resource "aws_s3_bucket_versioning" "website" {
  bucket = aws_s3_bucket.website.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_policy" "allow_public_access" {
  bucket = aws_s3_bucket.website.id

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "Statement1",
        "Principal" : "*",
        "Effect" : "Allow",
        "Action" : [
          "s3:GetObject",
          "s3:PutBucketPolicy",
          "s3:ListBucket",
          "S3:PutBucketPolicy",

        ],
        "Resource" : [
          "${aws_s3_bucket.website.arn}",
          "${aws_s3_bucket.website.arn}/*"
        ]
      }
    ]
  })
}


resource "null_resource" "deploy" {

  triggers = {
    always_run : "${timestamp()}"
  }

  provisioner "local-exec" {
    command = "aws s3 sync ../build s3://${aws_s3_bucket.website.bucket} --delete"
  }

}
