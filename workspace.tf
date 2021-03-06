locals {
  // Get workspace configuration data
  workspace_config = lookup(local.current_config, "workspace", {})

  // Format for workspace prefix
  workspace_prefix_format = lookup(
    local.workspace_config,
    "prefix_format",
    coalesce(var.workspace_prefix_format, "[a-zA-Z0-9-]+"),
  )

  // Format for environment name
  workspace_env_format = lookup(
    local.workspace_config,
    "environment_format",
    coalesce(var.workspace_env_format, "[a-zA-Z0-9]+"),
  )

  // Format for build name
  workspace_build_format = lookup(
    local.workspace_config,
    "build_format",
    coalesce(var.workspace_build_format, "[a-zA-Z0-9-]+"),
  )

  // Format for deployment name
  workspace_deployment_format = lookup(
    local.workspace_config,
    "deployment_format",
    coalesce(var.workspace_deployment_format, "[a-zA-Z0-9]+"),
  )

  // Character used to separate workspace
  workspace_prefix_separator = lookup(
    local.workspace_config,
    "prefix_separator",
    coalesce(var.workspace_prefix_separator, "-"),
  )

  // Character used to separate build
  workspace_build_separator = lookup(
    local.workspace_config,
    "build_separator",
    coalesce(var.workspace_build_separator, "_"),
  )

  // Character used to separate deployment
  workspace_deployment_separator = lookup(
    local.workspace_config,
    "deployment_separator",
    coalesce(var.workspace_deployment_separator, ":"),
  )

  // Construct workspace regex from above formats
  workspace_regex = format(
    "^(?:(?P<prefix>%s)%s)?(?P<environment>%s)(?:%s(?P<build>%s))?(?:%s(?P<deployment>%s))?$",
    local.workspace_prefix_format,
    local.workspace_prefix_separator,
    local.workspace_env_format,
    local.workspace_build_separator,
    local.workspace_build_format,
    local.workspace_deployment_separator,
    local.workspace_deployment_format,
  )

  // Create a map from the workspace regex results
  workspace_map = regex(local.workspace_regex, terraform.workspace)

  // List of keys not to use in the workspace prefix
  reserved_prefix_keys = concat([
    "prefix",
    ], [
    for k in keys(local.standard_tags) : lower(k)
  ])

  // Workspace prefix can have named capture groups so we
  // want to store those separte so that we can create
  // tags from them.
  workspace_prefix_map = {
    for k, v in local.workspace_map :
    k => v if !contains(local.reserved_prefix_keys, lower(k))
  }
}
