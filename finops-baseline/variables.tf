variable "region" {
  type    = string
  default = "eu-west-1"
}

variable "tags" {
  type = map(string)
  default = {
    "Module"    = "finops-baseline"
    "ManagedBy" = "Terraform"
  }
}

# Dataexports Destination Variables
variable "cid-dataexports-destination-stack-name" {
  description = "CloudFormation Stack Name"
  type        = string
  default     = "CID-DataExports-Destination"
}

variable "enable_scad" {
  description = "Enable Split Cost Allocation Data (SCAD)"
  type        = string
  default     = "yes"
}

variable "manage_coh" {
  description = "Enable Cost Optimization Hub (COH)"
  type        = string
  default     = "no"
}

variable "manage_cur2" {
  description = "Enable Cost and Usage Report 2.0 (CUR 2.0)"
  type        = string
  default     = "yes"
}

variable "manage_focus" {
  description = "Enable FOCUS export"
  type        = string
  default     = "no"
}

variable "resource_prefix" {
  description = "Resource Prefix for naming"
  type        = string
  default     = "cid"
}

variable "role_path" {
  description = "Path for IAM roles"
  type        = string
  default     = "/"
}

variable "time_granularity" {
  description = "Time granularity for CUR 2.0 export (HOURLY, DAILY, MONTHLY)"
  type        = string
  default     = "HOURLY"
}

variable "quicksight_admin_email" {
  description = "Email address of QuickSight administrator"
  type        = string
}

