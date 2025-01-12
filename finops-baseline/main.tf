locals {
  account_id                          = data.aws_caller_identity.current.account_id
  template_name                       = "cid-dataexports-destination.yaml"
  dataexports_destination_bucket_name = "${var.resource_prefix}-${local.account_id}-data-exports"
  # If the bucket does NOT exist, 'try()' returns null and does NOT fail the plan.
  # If the bucket DOES exist, it returns the actual bucket name.
  existing_bucket_name = try(data.aws_s3_bucket.data_exports_destination.bucket, null)

  # Convert existence to "true"/"false" for CF parameter
  use_existing_bucket = can(data.aws_s3_bucket.data_exports_destination.bucket) ? "yes" : "no"
}

data "aws_s3_bucket" "data_exports_destination" {
  bucket = local.dataexports_destination_bucket_name
}

module "s3-bucket" {
  source        = "terraform-aws-modules/s3-bucket/aws"
  version       = "4.3.0"
  bucket        = "cid-${local.account_id}-templates-bucket"
  force_destroy = true
  putin_khuylo  = true
}

resource "aws_s3_object" "data_exports_destination" {

  key    = local.template_name
  bucket = module.s3-bucket.s3_bucket_id
  source = "${path.module}/stack-templates/${local.template_name}"

  force_destroy = true
}

resource "aws_cloudformation_stack" "data_exports_destination" {
  name         = var.cid-dataexports-destination-stack-name
  template_url = "https://${module.s3-bucket.s3_bucket_id}.s3.amazonaws.com/${local.template_name}"

  parameters = {
    DestinationAccountId = local.account_id
    UseExistingBucket    = local.use_existing_bucket
    EnableSCAD           = var.enable_scad
    ManageCOH            = var.manage_coh
    ManageCUR2           = var.manage_cur2
    ManageFOCUS          = var.manage_focus
    ResourcePrefix       = var.resource_prefix
    RolePath             = var.role_path
    SourceAccountIds     = local.account_id
    TimeGranularity      = var.time_granularity
  }

  capabilities = ["CAPABILITY_NAMED_IAM"]
}

module "cur_destination" {
  depends_on = [aws_cloudformation_stack.data_exports_destination]
  source     = "github.com/aws-samples/aws-cudos-framework-deployment//terraform-modules/cur-setup-destination?ref=4.0.7"

  source_account_ids = [local.account_id]
  create_cur         = false

  # Provider alias for us-east-1 must be passed explicitly (required for CUR setup)
  providers = {
    aws.useast1 = aws.use1
  }
}

module "cur_source" {
  depends_on = [module.cur_destination]
  source     = "github.com/aws-samples/aws-cudos-framework-deployment//terraform-modules/cur-setup-source?ref=4.0.7"

  destination_bucket_arn = module.cur_destination.cur_bucket_arn

  # Provider alias for us-east-1 must be passed explicitly (required for CUR setup)
  providers = {
    aws.useast1 = aws.use1
  }
}
