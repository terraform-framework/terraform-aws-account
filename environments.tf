locals {
  // Get environment configuration
  environments_config = lookup(local.current_config, "environments", {})

  // Lookup environment name using workspace context unless explicitly overridden.
  // This is useful for `default` workspace scenarios where we're not using the
  // terraform workspaces features.
  current_env_name = coalesce(var.environment_override, lookup(local.workspace_map, "environment"))

  // Lookup build and stage names from workspace context
  current_build_name = lookup(local.workspace_map, "build")
  current_stage_name = lookup(local.workspace_map, "stage")

  // Load current environment from config based on workspace
  current_environment = lookup(
    // For some reason this is not working without the merge due to some
    // internal type assumptions.
    merge({}, local.environments_config),
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
