locals {
  // Lookup environment name using workspace context unless explicitly overridden.
  // This is useful for `default` workspace scenarios where we're not using the
  // terraform workspaces features.
  current_env_name = coalesce(var.environment_override, lookup(local.workspace_map, "environment"))

  // Lookup build and deployment names from workspace context
  current_build_name      = lookup(local.workspace_map, "build")
  current_deployment_name = lookup(local.workspace_map, "deployment")

  // Get and normalize environment configuration
  environments = {
    for k, v in lookup(local.current_config, "environments", {}) : k => {
      // Environment name
      name = k

      // Fully qualified subdomain for the environment
      domain = lower(format("%s.%s", join(".", compact([
        for part in split(".", local.subdomain_template) :
        format(replace(part, format("/%s/", local.template_keys), "%s"), [
          for value in flatten(regexall(local.template_keys, part)) :
          lookup(merge(local.template_vars, {
            environment = k
            build       = ""
            deployment  = ""
          }), value)
        ]...)
      ])), local.root_domain))

      // Network details for environment
      network = {
        cidr_blocks = lookup(v, "cidr_blocks", [])
        subnets     = lookup(v, "subnets", {})
      }

      // Custom properties for the environment
      custom = lookup(v, "custom", {})
    }
  }

  // Load current environment from config based on workspace
  current_environment = merge({
    // Environment name
    name = local.current_env_name

    // Virtual build name
    build = local.current_build_name

    // Deployment name
    deployment = local.current_deployment_name

    // Fully qualified subdomain for the environment
    domain = lower(format("%s.%s", join(".", compact([
      for part in split(".", local.subdomain_template) :
      format(replace(part, format("/%s/", local.template_keys), "%s"), [
        for value in flatten(regexall(local.template_keys, part)) :
        lookup(merge(local.template_vars, {
          build      = ""
          deployment = ""
        }), value)
      ]...)
    ])), local.root_domain))

    // Empty network configuration
    network = {
      cidr_blocks = []
      subnets     = {}
    }
  }, lookup(local.environments, local.current_env_name, {}))
}
