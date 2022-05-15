locals {
  root_domain = lookup(
    local.account_config,
    "domain",
    format("%s.local", local.account_name),
  )
}

output "root" {
  value = {
    // Domain name for the root of the account
    domain = local.root_domain

    // CIDR blocks assigned to the account
    cidr_blocks = lookup(local.account_config, "cidr_blocks", [])
  }
}
