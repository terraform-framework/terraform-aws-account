locals {
  // Get environment configuration
  environments_config = lookup(local.current_config, "environments", {})

  // Lookup environment name using workspace context unless explicitly overridden.
  // This is useful for `default` workspace scenarios where we're not using the
  // terraform workspaces features.
  current_env_name = coalesce(var.environment_override, lookup(local.workspace_map, "environment"))

  // Lookup build and deployment names from workspace context
  current_build_name      = lookup(local.workspace_map, "build")
  current_deployment_name = lookup(local.workspace_map, "deployment")

  // Load current environment from config based on workspace
  current_environment = lookup(
    // For some reason this is not working without the merge due to some
    // internal type assumptions.
    merge({}, local.environments_config),
    local.current_env_name, {}
  )

  // Environment scoped domain
  env_domain = lower(join(".", [
    lookup(local.current_environment, "subdomain", local.current_env_name),
    local.root_domain,
  ]))
}

output "env" {
  value = {
    // Name of the environment
    name = local.current_env_name

    // Virtual build name
    build = local.current_build_name

    // Deployment name
    deployment = local.current_deployment_name

    // Domain for the environment with build
    build_domain = lower(join(".", compact([
      local.current_build_name,
      local.env_domain,
    ])))

    // Domain for the environment including deployment
    deployment_domain = lower(join(".", compact([
      local.current_deployment_name,
      local.current_build_name,
      local.env_domain,
    ])))

    // Domain scoped just to the environment
    domain = local.env_domain
  }
}

output "envs" {
  value = keys(local.environments_config)
}
