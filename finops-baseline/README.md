# aa-tf-modules

Collection of Terraform modules for AWS infrastructure deployment.

## Modules

### finops-baseline

Sets up AWS FinOps infrastructure including:

- Cost and Usage Report (CUR) configuration
- Data exports destination setup
- CUDOS framework integration
- Cost Optimization Hub integration

## Usage

```hcl
module "finops_baseline" {
  source = "github.com/struk77/aa-tf-modules//finops-baseline"

  # Required variables
  resource_prefix = "cid"
  enable_scad = "yes"
  manage_coh = "yes"
  manage_cur2 = "yes"
  manage_focus = "yes"
}

## Destroying resources

All resource could be destroyed automatically by Terraform. There are two exceptions:

- Quicksight Subscription termination protection should be disabled before destroying the module.

```shell
aws quicksight update-account-settings --no-termination-protection-enabled --aws-account-id <account_id> --default-namespace default
```

- BCM Data Export should be removed manually.
