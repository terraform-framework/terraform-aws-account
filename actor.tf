// Create an ARN resource of the caller ARN string
data "aws_arn" "this" {
  arn = data.aws_caller_identity.this.arn
}

locals {
  // Determine if ARN belongs to token service
  is_assumed_role = data.aws_arn.this.service == "sts"

  // Split the resource by path so we can get the username/role at the end
  actor_parts = split("/", data.aws_arn.this.resource)

  // Store number of parts in the list
  actor_length = length(local.actor_parts)

  // Opinionated separator for the actor name using period. This is based
  // on common approach to naming IAM users but may need a rework to suit
  // other situations.
  actor_name = join(" ", split(".", title(
    local.is_assumed_role ? local.actor_parts[1] : local.actor_parts[local.actor_length - 1]
  )))

  // Collect other parts of the IAM ARN for things like the assumed role session.
  actor_slice   = local.is_assumed_role ? slice(local.actor_parts, 0, 1) : slice(local.actor_parts, 0, local.actor_length - 1)
  actor_session = local.is_assumed_role ? local.actor_parts[local.actor_length - 1] : null
}
