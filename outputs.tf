output "id" {
  value = data.aws_caller_identity.this.account_id

  description = "The AWS account ID of the account that corresponds to the credentials being used - the current account."
}

output "name" {
  value = local.account_name

  description = "The friendly name mapped to the account ID. This is loaded from the specified config, otherwise defaults to the account ID."
}

output "actor" {
  value = {
    name    = local.actor_name
    path    = format("%s/", join("/", local.actor_slice))
    session = local.actor_session
  }

  description = "The details of the user or role invoking the AWS API."
}

output "envs" {
  value = {
    for k, v in local.environments_config : k => {
      name = k

      domain = lower(join(".", [
        lookup(lookup(local.environments_config, k, {}), "subdomain", k),
        local.root_domain,
      ]))

      network = {
        cidr_blocks = lookup(v, "cidr_blocks", [])
        subnets     = lookup(v, "subnets", {})
      }
    }
  }

  description = "A map of environment names to their network configurations."
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

  description = "Details about the currently selected environment. This will be loaded from configuration and scoped to a particular environment based on the workspace."
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

  description = "Details about the feature build environment within the currently selected environment."
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

  description = "Details about the deployment environment within the currently selected environment."
}

output "is" {
  value = local.helper_is

  description = "A map of boolean helper outputs to reflect on whether the known accounts and environments are currently selected."
}

output "ids" {
  value = {
    for id, conf in local.config_data :
    (conf.account.name) => id
  }

  description = "A list of known account IDs from all known configurations."
}

output "resource_name" {
  value = {
    format    = replace(lower(local.resource_name), "/!!!/", "%s")
    prefix    = lower(local.resource_name_prefix)
    suffix    = lower(local.resource_name_suffix)
    separator = local.resource_name_separator
  }

  description = "An object detailing the naming format and standards for resource names."
}

output "tag_name" {
  value = {
    format    = replace(upper(local.tag_name), "/!!!/", "%s")
    prefix    = upper(local.tag_name_prefix)
    suffix    = upper(local.tag_name_suffix)
    separator = local.tag_name_separator
  }

  description = "An object detailing the naming format and standards for the `Name` tag."
}

output "region" {
  value = {
    name        = data.aws_region.this.name
    description = data.aws_region.this.description
    zones       = data.aws_availability_zones.this.names
  }

  description = "A map with details about the currently invoked region and it's zones filtered by the `zone_state` variable."
}

output "root" {
  value = {
    // Domain name for the root of the account
    domain = local.root_domain

    // CIDR blocks assigned to the account
    cidr_blocks = lookup(local.account_config, "cidr_blocks", [])
  }

  description = "A map containing account level configuration such as domain name and CIDR ranges."
}

output "tags" {
  value = local.tags

  description = "A map of key value pairs for all tags to be propogated to resources and modules."
}

output "workspace" {
  value = {
    prefix    = lookup(local.workspace_map, "prefix")
    separator = local.workspace_prefix_separator
  }

  description = "A map of workspace details useful for constructing remote state data sources."
}
