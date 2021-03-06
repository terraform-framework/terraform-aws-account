locals {
  // Ensure these keys are set always
  default_template_vars = {
    deployment    = ""
    build         = ""
    created_actor = ""
    updated_actor = ""
  }

  // Convert tags to lowercase and remove any spaces
  tag_vars = {
    for k, v in local.tags :
    lower(replace(replace(k, "/([a-z])([A-Z])/", "$1 $2"), " ", "_")) => v
  }

  // Variables from standard and tags
  template_vars = merge(local.default_template_vars, local.tag_vars, {
    name   = "!!!"
    prefix = ""
    suffix = ""
  })

  // All variable keys
  template_keys = format("{(%s)}", join("|", keys(local.template_vars)))

  // Get naming standards from config
  naming_config = lookup(local.current_config, "naming", {})

  // Load the environment domain template from the config or fallback to the default value
  domain_template = lookup(
    local.naming_config,
    "domain_template",
    coalesce(var.domain_template, "{environment}")
  )

  // Load the environment subdomain template from the config or fallback to the default value
  subdomain_template = lookup(
    local.naming_config,
    "subdomain_template",
    coalesce(var.subdomain_template, "{deployment}.{build}")
  )

  // Load the resource name separator from the config
  // or fallback to the default value
  resource_name_separator = lookup(
    local.naming_config,
    "resource_name_separator",
    coalesce(var.resource_name_separator, "-"),
  )

  // Load the resource name prefix template from the config
  // or fallback to the default value
  resource_name_prefix_template = lookup(
    local.naming_config,
    "resource_name_prefix_template",
    coalesce(var.resource_name_prefix_template, "{environment}"),
  )

  // Load the resource name suffix template from the config
  // or fallback to the default value
  resource_name_suffix_template = lookup(
    local.naming_config,
    "resource_name_suffix_template",
    coalesce(var.resource_name_suffix_template, "{deployment}"),
  )

  // Load the resource name template from the config
  // or fallback to the default value
  resource_name_template = lookup(
    local.naming_config,
    "resource_name_template",
    coalesce(var.resource_name_template, "{prefix}{sep}{build}{sep}{name}{sep}{suffix}"),
  )

  // Construct the resource name prefix from the template
  resource_name_prefix = join(local.resource_name_separator, compact([
    for part in split("{sep}", local.resource_name_prefix_template) :
    format(replace(part, format("/%s/", local.template_keys), "%s"), [
      for value in flatten(regexall(local.template_keys, part)) :
      lookup(local.template_vars, value)
    ]...)
  ]))

  // Construct the resource name suffix from the template
  resource_name_suffix = join(local.resource_name_separator, compact([
    for part in split("{sep}", local.resource_name_suffix_template) :
    format(replace(part, format("/%s/", local.template_keys), "%s"), [
      for value in flatten(regexall(local.template_keys, part)) :
      lookup(local.template_vars, value)
    ]...)
  ]))

  // Construct the resource name suffix from the template
  resource_name = join(local.resource_name_separator, compact([
    for part in split("{sep}", local.resource_name_template) :
    format(replace(part, format("/%s/", local.template_keys), "%s"), [
      for value in flatten(regexall(local.template_keys, part)) :
      lookup(merge(local.template_vars, {
        prefix = local.resource_name_prefix
        suffix = local.resource_name_suffix
      }), value)
    ]...)
  ]))

  // Load the tag name separator from the config
  // or fallback to the default value
  tag_name_separator = lookup(
    local.naming_config,
    "tag_name_separator",
    coalesce(var.tag_name_separator, "/"),
  )

  // Load the tag name prefix template from the config
  // or fallback to the default value
  tag_name_prefix_template = lookup(
    local.naming_config,
    "tag_name_prefix_template",
    coalesce(var.tag_name_prefix_template, "{account}{sep}{environment}"),
  )

  // Load the tag name suffix template from the config
  // or fallback to the default value
  tag_name_suffix_template = lookup(
    local.naming_config,
    "tag_name_suffix_template",
    coalesce(var.tag_name_suffix_template, "{deployment}"),
  )

  // Load the tag name template from the config
  // or fallback to the default value
  tag_name_template = lookup(
    local.naming_config,
    "tag_name_template",
    coalesce(var.tag_name_template, "{prefix}{sep}{build}{sep}{name}{sep}{suffix}"),
  )

  // Construct the tag name prefix from the template
  tag_name_prefix = join(local.tag_name_separator, [
    for x in compact([
      for part in split("{sep}", local.tag_name_prefix_template) :
      format(replace(part, format("/%s/", local.template_keys), "%s"), [
        for value in flatten(regexall(local.template_keys, part)) :
        lookup(local.template_vars, value)
      ]...)
    ]) : lookup(var.resource_tag_codes, x, x)
  ])

  // Construct the tag name suffix from the template
  tag_name_suffix = join(local.tag_name_separator, [
    for x in compact([
      for part in split("{sep}", local.tag_name_suffix_template) :
      format(replace(part, format("/%s/", local.template_keys), "%s"), [
        for value in flatten(regexall(local.template_keys, part)) :
        lookup(local.template_vars, value)
      ]...)
    ]) : lookup(var.resource_tag_codes, x, x)
  ])

  // Construct the tag name suffix from the template
  tag_name = join(local.tag_name_separator, [
    for x in compact([
      for part in split("{sep}", local.tag_name_template) :
      format(replace(part, format("/%s/", local.template_keys), "%s"), [
        for value in flatten(regexall(local.template_keys, part)) :
        lookup(merge(local.template_vars, {
          prefix = local.tag_name_prefix
          suffix = local.tag_name_suffix
        }), value)
      ]...)
    ]) : lookup(var.resource_tag_codes, x, x)
  ])
}
