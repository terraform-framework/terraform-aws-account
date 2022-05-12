output "is" {
  value = merge({
    for id, conf in local.config_data :
    (conf.account.name) => (data.aws_caller_identity.this.account_id == id)
    }, {
    for env in keys(local.environments_config) :
    env => (env == local.current_env_name)
  })
}

output "ids" {
  value = {
    for id, conf in local.config_data :
    (conf.account.name) => id
  }
}
