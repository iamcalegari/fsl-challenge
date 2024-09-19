output "website_bucket" {
  value = aws_s3_bucket.website.bucket
}

output "website_bucket_arn" {
  value = aws_s3_bucket.website.arn
}
