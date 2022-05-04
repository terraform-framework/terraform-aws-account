output "is" {
  value = merge({
    for id, conf in local.config_data :
    (conf.account.name) => (data.aws_caller_identity.this.account_id == id)
    }, {

  })
}

output "ids" {
  value = {
    for id, conf in local.config_data :
    (conf.account.name) => id
  }
}
