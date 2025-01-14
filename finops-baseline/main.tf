locals {
  account_id                          = data.aws_caller_identity.current.account_id
  account_name                        = data.aws_iam_account_alias.current.account_alias
  template_name                       = "data-exports-aggregation.yaml"
  templates_bucket_name               = "${var.resource_prefix}-${local.account_id}-templates-bucket"
  dataexports_destination_bucket_name = "${var.resource_prefix}-${local.account_id}-data-exports"
  data_exports_destination_bucket_arn = "arn:aws:s3:::${local.dataexports_destination_bucket_name}"
  data_local_bucket_name              = "${var.resource_prefix}-${local.account_id}-data-local"
  data_local_bucket_arn               = "arn:aws:s3:::${local.data_local_bucket_name}"
}

module "templates-bucket" {
  source        = "terraform-aws-modules/s3-bucket/aws"
  version       = "4.3.0"
  bucket        = "cid-${local.account_id}-templates-bucket"
  force_destroy = true
  putin_khuylo  = true
}

module "data_exports_destination_bucket" {
  source        = "terraform-aws-modules/s3-bucket/aws"
  version       = "4.3.0"
  bucket        = local.dataexports_destination_bucket_name
  force_destroy = true
  putin_khuylo  = true
  versioning = {
    enabled    = true
    mfa_delete = false
  }
  lifecycle_rule = [
    {
      enabled = true
      id      = "Object&Version Expiration"

      noncurrent_version_expiration = {
        noncurrent_days = 32
      }
    }
  ]
  policy = jsonencode({
    Id      = "AllowReplication"
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowTLS12Only"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          "${local.data_exports_destination_bucket_arn}",
          "${local.data_exports_destination_bucket_arn}/*"
        ]
        Condition = {
          NumericLessThan = {
            "s3:TlsVersion" = 1.2
          }
        }
      },
      {
        Sid       = "AllowOnlyHTTPS"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          "${local.data_exports_destination_bucket_arn}",
          "${local.data_exports_destination_bucket_arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = false
          }
        }
      },
      {
        Sid       = "AllowReplicationWrite"
        Effect    = "Allow"
        Principal = [local.account_id]
      },
      {
        Sid       = "AllowReplicationRead"
        Effect    = "Allow"
        Principal = [local.account_id]
        Action = [
          "s3:ListBucket",
          "s3:ListBucketVersions",
          "s3:GetBucketVersioning",
          "s3:PutBucketVersioning"
        ]
        Resource = "${local.data_exports_destination_bucket_arn}"
      }
    ]
    }
  )
}

module "data_local_bucket" {
  source        = "terraform-aws-modules/s3-bucket/aws"
  version       = "4.3.0"
  bucket        = local.data_local_bucket_name
  force_destroy = true
  putin_khuylo  = true
  versioning = {
    status     = true
    mfa_delete = false
  }
  lifecycle_rule = [
    {
      enabled = true
      id      = "Object&Version Expiration"
      noncurrent_version_expiration = {
        noncurrent_days = 32
      }
      expiration = {
        days = 64
      }
    }
  ]
  replication_configuration = {
    role = aws_iam_role.replication_role.arn
    rules = [
      {
        id       = "ReplicateCUR2Data"
        priority = 1
        prefix   = "cur2/${local.account_id}/${var.resource_prefix}-cur2/data/"
        status   = "Enabled"
        destination = {
          bucket        = local.data_exports_destination_bucket_arn
          storage_class = "STANDARD"
        }
        delete_marker_replication = false
      },
      {
        id       = "ReplicateFOCUSData"
        priority = 2
        prefix   = "focus/${local.account_id}/${var.resource_prefix}-focus/data/"
        status   = "Enabled"
        destination = {
          bucket        = local.data_exports_destination_bucket_arn
          storage_class = "STANDARD"
        }
        delete_marker_replication = false
      },
      {
        id       = "ReplicateCOHData"
        priority = 3
        prefix   = "coh/${local.account_id}/${var.resource_prefix}-coh/data/"
        status   = "Enabled"
        destination = {
          bucket        = local.data_exports_destination_bucket_arn
          storage_class = "STANDARD"
        }
        delete_marker_replication = false
      }
    ]
  }
}

resource "aws_iam_role" "replication_role" {
  name = "${var.resource_prefix}_ReplicationRole"
  path = "/${var.resource_prefix}/"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "replication_policy" {
  name        = "${var.resource_prefix}_ReplicationPolicy"
  description = "Policy for S3 replication"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket"
        ]
        Resource = "${local.data_local_bucket_arn}"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging"
        ]
        Resource = "${local.data_local_bucket_arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags"
        ]
        Resource = "${local.data_exports_destination_bucket_arn}/*/${local.account_id}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "replication_policy_attachment" {
  role       = aws_iam_role.replication_role.name
  policy_arn = aws_iam_policy.replication_policy.arn
}

resource "aws_s3_object" "data_exports_destination" {

  key    = local.template_name
  bucket = module.templates-bucket.s3_bucket_id
  source = "${path.module}/stack-templates/${local.template_name}"

  force_destroy = true
}

resource "aws_cloudformation_stack" "data_exports_destination" {
  depends_on   = [module.data_exports_destination_bucket, aws_s3_object.data_exports_destination, module.data_local_bucket]
  name         = var.cid-dataexports-destination-stack-name
  template_url = "https://${module.templates-bucket.s3_bucket_id}.s3.amazonaws.com/${local.template_name}"

  parameters = {
    DestinationAccountId = local.account_id
    DestinationS3        = local.dataexports_destination_bucket_name
    SourceS3             = local.data_local_bucket_name
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
