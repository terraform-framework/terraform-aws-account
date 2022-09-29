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
  value = local.environments

  description = "A map of environment names to their network configurations."
}

output "env" {
  value = local.current_environment

  description = "Details about the currently selected environment. This will be loaded from configuration and scoped to a particular environment based on the workspace."
}

output "build" {
  value = {
    // Name of the environment  build
    name = local.current_build_name

    // Domain scoped to the build
    domain = lower(join(".", compact([
      join(".", compact([
        for part in split(".", local.subdomain_template) :
        format(replace(part, format("/%s/", local.template_keys), "%s"), [
          for value in flatten(regexall(local.template_keys, part)) :
          lookup(merge(local.template_vars, {
            environment = local.current_env_name
            deployment  = ""
          }), value)
        ]...)
    ])), local.current_environment.domain])))
  }

  description = "Details about the feature build environment within the currently selected environment."
}

output "deployment" {
  value = {
    // Name of the environment deployment
    name = local.current_deployment_name

    // Domain scoped to the deployment
    domain = lower(join(".", compact([
      join(".", compact([
        for part in split(".", local.subdomain_template) :
        format(replace(part, format("/%s/", local.template_keys), "%s"), [
          for value in flatten(regexall(local.template_keys, part)) :
          lookup(merge(local.template_vars, {
            environment = local.current_env_name
          }), value)
        ]...)
    ])), local.current_environment.domain])))
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
