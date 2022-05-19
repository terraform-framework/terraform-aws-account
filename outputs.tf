output "id" {
  value = data.aws_caller_identity.this.account_id
}

output "name" {
  value = local.account_name
}

output "actor" {
  value = {
    name    = local.actor_name
    path    = format("%s/", join("/", local.actor_slice))
    session = local.actor_session
  }
}

output "envs" {
  value = keys(local.environments_config)
}

output "env" {
  value = {
    // Name of the environment
    name = local.current_env_name

    // Virtual build name
    build = local.current_build_name

    // Deployment name
    deployment = local.current_deployment_name

    // Domain scoped just to the environment
    domain = local.env_domain

    // Filter network configuration
    network = {
      // CIDR block assigned to the whole network
      cidr_blocks = lookup(local.current_environment, "cidr_blocks", [])

      // Map of subnet group names to subnet CIDR blocks
      subnets = lookup(local.current_environment, "subnets", {})
    }

    // Custom configuration
    custom = lookup(local.current_environment, "custom", {})
  }
}

output "build" {
  value = {
    // Name of the environment  build
    name = local.current_build_name

    // Domain scoped to the build
    domain = lower(join(".", compact([
      local.current_build_name,
      local.env_domain,
    ])))
  }
}

output "deployment" {
  value = {
    // Name of the environment deployment
    name = local.current_deployment_name

    // Domain scoped to the deployment
    deployment_domain = lower(join(".", compact([
      local.current_deployment_name,
      local.current_build_name,
      local.env_domain,
    ])))
  }
}

output "is" {
  value = local.helper_is
}

output "ids" {
  value = {
    for id, conf in local.config_data :
    (conf.account.name) => id
  }
}

output "resource_name" {
  value = {
    format    = replace(lower(local.resource_name), "/!!!/", "%s")
    prefix    = lower(local.resource_name_prefix)
    suffix    = lower(local.resource_name_suffix)
    separator = local.resource_name_separator
  }
}

output "tag_name" {
  value = {
    format    = replace(upper(local.tag_name), "/!!!/", "%s")
    prefix    = upper(local.tag_name_prefix)
    suffix    = upper(local.tag_name_suffix)
    separator = local.tag_name_separator
  }
}

output "region" {
  value = {
    name        = data.aws_region.this.name
    description = data.aws_region.this.description
    zones       = data.aws_availability_zones.this.names
  }
}

output "root" {
  value = {
    // Domain name for the root of the account
    domain = local.root_domain

    // CIDR blocks assigned to the account
    cidr_blocks = lookup(local.account_config, "cidr_blocks", [])
  }
}

output "tags" {
  value = local.tags
}

output "workspace" {
  value = {
    prefix    = lookup(local.workspace_map, "prefix")
    separator = local.workspace_prefix_separator
  }
}
