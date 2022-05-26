locals {
  helper_is_account = {
    for id, conf in local.config_data :
    (conf.account.name) => (data.aws_caller_identity.this.account_id == id)
  }

  helper_is_env = {
    for env in toset(compact(concat([""], [
      for account in local.config_data : keys(lookup(account, "environments", {}))
    ]...))) : env => (env == local.current_env_name)
  }

  helper_is_unknown = !anytrue(concat(
    values(local.helper_is_account),
    values(local.helper_is_env),
  ))

  helper_is = {
    // Is account helper
    account = local.helper_is_account

    // Is environment helper
    env = merge({
      // Special helper to always reflect current env as true
      (local.current_env_name) = true
    }, local.helper_is_env)

    // Is a build environment
    build = (local.current_build_name != null)

    // Is a deployment environment
    deployment = (local.current_deployment_name != null)

    // Is either account or env unknown to config
    unknown = local.helper_is_unknown
  }
}

output "unknown" {
  value = local.helper_is_unknown
}
