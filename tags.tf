locals {
  // Lookup account scoped tags
  account_tags = lookup(local.account_config, "tags", {})

  // Tags relating to actor tracking
  actor_tags = merge(var.track_actor && var.track_actor_created ? {
    CreatedActor = local.actor_name
    } : {}, var.track_actor && var.track_actor_updated ? {
    UpdatedActor = local.actor_name
  } : {})

  // Tags relating to feature builds and stages
  env_tags = merge(local.current_build_name != null ? {
    Build = local.current_build_name
    } : {}, local.current_stage_name != null ? {
    Stage = local.current_stage_name
  } : {})

  // Compile all tags together
  tags = merge(
    local.account_tags,
    local.env_tags,
    local.actor_tags,
    var.tags,
  )
}

output "tags" {
  value = local.tags
}
