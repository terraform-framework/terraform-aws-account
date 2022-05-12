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

  // Format for stage name
  workspace_stage_format = lookup(
    local.workspace_config,
    "stage_format",
    coalesce(var.workspace_stage_format, "[a-zA-Z0-9]+"),
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

  // Character used to separate stage
  workspace_stage_separator = lookup(
    local.workspace_config,
    "stage_separator",
    coalesce(var.workspace_stage_separator, ":"),
  )

  // Construct workspace regex from above formats
  workspace_regex = format(
    "^(%s%s)?(%s)(?:%s(%s))?(?:%s(%s))?$",
    local.workspace_prefix_format,
    local.workspace_prefix_separator,
    local.workspace_env_format,
    local.workspace_build_separator,
    local.workspace_build_format,
    local.workspace_stage_separator,
    local.workspace_stage_format,
  )

  // Create a map from the workspace regex results
  workspace_map = zipmap([
    "prefix",
    "environment",
    "build",
    "stage",
  ], flatten(regexall(local.workspace_regex, terraform.workspace)))
}
