data "aws_caller_identity" "this" {
  // Get the identity of the current caller
}

// Load remote data if a remote config URL is provided
data "http" "remote" {
  for_each = toset(compact([var.remote_config_url]))

  url             = var.remote_config_url
  request_headers = var.remote_config_headers
}

locals {
  // Load local file based configuration
  config_local = var.local_config_path != null ? {
    for fname in fileset(var.local_config_path, "*.yml") :
    element(split(".", basename(fname)), 0) => yamldecode(file(format("%s/%s", var.local_config_path, fname)))
  } : {}

  // Load remote URL based configuration
  config_remote = var.remote_config_url != null ? merge([
    for v in data.http.remote : jsondecode(v.body)
  ]...) : {}

  // Merge local and remote configurations. Local always takes
  // presedence over remote configuration.
  config_data = merge({},
    local.config_remote,
    local.config_local,
  )

  // Load the current account into own local
  current_config = lookup(
    local.config_data,
    data.aws_caller_identity.this.account_id,
    {},
  )
}
