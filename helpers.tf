locals {
  helper_is_account = {
    for id, conf in local.config_data :
    (conf.account.name) => (data.aws_caller_identity.this.account_id == id)
    if conf.grouping == lookup(local.current_config, "grouping", {})
  }

  helper_is_env = {
    for env in toset(compact(concat([""], [
      for account in local.config_data :
      keys(lookup(account, "environments", {}))
      if account.grouping == lookup(local.current_config, "grouping", {})
    ]...))) : env => (env == local.current_env_name)
  }

  helper_grouping_keys = try(toset(concat([
    for acc in local.config_data :
    keys(lookup(acc, "grouping", {}))
  ]...)), [])

  helper_is_group = {
    for key in local.helper_grouping_keys :
    key => {
      for value in toset([
        for acc in local.config_data :
        lookup(lookup(acc, "grouping", {}), key, [])
      ]) : value => lookup(lookup(local.current_config, "grouping", {}), key, []) == value
    }
  }

  helper_is = merge(local.helper_is_group, {
    // Is account helper
    account = merge({
      unknown = !anytrue(values(local.helper_is_account))
    }, local.helper_is_account)

    // Is environment helper
    env = merge({
      // Special helper to always reflect current env as true
      (local.current_env_name) = true

      // Whether environment is unknown
      unknown = !anytrue(values(local.helper_is_env))
    }, local.helper_is_env)

    // Is a build environment
    build = (local.current_build_name != null)

    // Is a deployment environment
    deployment = (local.current_deployment_name != null)

    // Is account and environment unknown to config
    unknown = !anytrue(concat(
      values(local.helper_is_account),
      values(local.helper_is_account),
    ))
  })
}
