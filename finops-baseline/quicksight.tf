resource "aws_quicksight_account_subscription" "subscription" {
  account_name          = local.account_name
  authentication_method = "IAM_AND_QUICKSIGHT"
  edition               = "ENTERPRISE"
  notification_email    = var.quicksight_admin_email
}

resource "aws_quicksight_namespace" "namespace" {
  depends_on = [aws_quicksight_account_subscription.subscription]
  namespace  = local.account_name
}

resource "aws_quicksight_user" "dashboards_user" {
  depends_on     = [aws_quicksight_account_subscription.subscription, aws_quicksight_namespace.namespace]
  email          = var.quicksight_admin_email
  identity_type  = "QUICKSIGHT"
  user_role      = "ADMIN"
  user_name      = "dashboards_user"
  aws_account_id = local.account_id
}
