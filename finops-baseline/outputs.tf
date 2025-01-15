output "templates_bucket_id" {
  description = "ID of the S3 bucket containing CloudFormation templates"
  value       = module.templates-bucket.s3_bucket_id
}

output "templates_bucket_arn" {
  description = "ARN of the S3 bucket containing CloudFormation templates"
  value       = module.templates-bucket.s3_bucket_arn
}

output "data_exports_stack_id" {
  description = "CloudFormation stack ID for data exports destination"
  value       = aws_cloudformation_stack.data_exports_destination.id
}

output "cur_destination_bucket_arn" {
  description = "ARN of the CUR destination bucket"
  value       = module.cur_destination.cur_bucket_arn
}

output "cur_destination_bucket_name" {
  description = "Name of the CUR destination bucket"
  value       = module.cur_destination.cur_bucket_name
}

output "account_id" {
  description = "AWS Account ID where resources are deployed"
  value       = local.account_id
}

output "account_name" {
  description = "AWS Account Name"
  value       = local.account_name
}

output "quicksight_admin_email" {
  description = "Email address of the Quicksight admin user"
  value       = var.quicksight_admin_email
}
