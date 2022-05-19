locals {
  root_domain = lookup(
    local.account_config,
    "domain",
    format("%s.local", local.account_name),
  )
}
