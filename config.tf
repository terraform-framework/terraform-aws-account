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
  config_subpath = var.local_config_subpath == null ? "" : var.local_config_subpath

  // Create subpath matcher from subpath tokens
  config_subpath_match = replace(local.config_subpath, "/{([a-z]+)}/", "*")

  // Create regex with named capture groups matching placeholder
  // in the subpath string
  config_path_regex = var.local_config_path == null ? "" : join("/", concat([var.local_config_path], [
    for part in split("/", local.config_subpath) :
    try(
      format("(?P<%s>[a-zA-Z0-9_-]+)", regex("{([a-z]+)}", part)[0]),
      part,
    )
  ]))

  // Filters for selecting config files including subpath
  config_path_filter_yaml = format("%s/*.{yml,yaml}", local.config_subpath_match)
  config_path_filter_json = format("%s/*.json", local.config_subpath_match)

  // Load local file based configuration
  config_local = merge([
    for path in compact([var.local_config_path]) : merge({
      for fname in fileset(path, local.config_path_filter_yaml) :
      element(split(".", basename(fname)), 0) => merge(yamldecode(file(format("%s/%s", path, fname))), {
        grouping = try(merge(regex(local.config_path_regex, join("/", [path, fname]))), {})
      })
      }, {
      for fname in fileset(path, local.config_path_filter_json) :
      element(split(".", basename(fname)), 0) => merge(jsondecode(file(format("%s/%s", path, fname))), {
        grouping = try(merge(regex(local.config_path_regex, join("/", [path, fname]))), {})
      })
    })
  ]...)

  // Load remote URL based configuration
  config_remote = var.remote_config_url != null ? merge([
    for v in data.http.remote : jsondecode(v.body)
  ]...) : {}

  // Merge local and remote configurations. Local always takes
  // presedence over remote configuration.
  config_data = merge(
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
