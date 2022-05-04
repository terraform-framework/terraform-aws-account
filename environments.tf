locals {
  // Get environment configuration
  environments_config = lookup(local.current_config, "environments", {})

  // Lookup environment name using workspace context unless explicitly overridden.
  // This is useful for `default` workspace scenarios where we're not using the
  // terraform workspaces features.
  current_env_name = var.workspace_override != null ? var.workspace_override : lookup(local.workspace_map, "environment")

  // Lookup build and stage names from workspace context
  current_build_name = lookup(local.workspace_map, "build")
  current_stage_name = lookup(local.workspace_map, "stage")

  // Load current environment from config based on workspace
  current_environment = lookup(
    local.environments_config,
    local.current_env_name, {}
  )
}

output "env" {
  value = {
    // Name of the environment
    name = local.current_env_name

    // Virtual build name
    build = local.current_build_name

    // Stage name
    stage = local.current_stage_name
  }
}
