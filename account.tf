locals {
  // Load the account for which the invoked credentials are for
  // into a local, this will be used for scoped config lookups
  account_config = lookup(local.current_config, "account", {})

  // Name of the current account
  account_name = lookup(
    local.account_config, "name",
    data.aws_caller_identity.this.account_id,
  )
}
