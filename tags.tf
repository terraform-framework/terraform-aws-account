locals {
  // Lookup account scoped tags
  account_tags = lookup(local.account_config, "tags", {})

  // Tags relating to actor tracking
  actor_tags = merge(var.track_actor && var.track_actor_created ? {
    CreatedActor = local.actor_name
    } : {}, var.track_actor && var.track_actor_updated ? {
    UpdatedActor = local.actor_name
  } : {})

  // Tags relating to git trackign
  git_tags = merge(var.track_git ? {
    GitAuthorName   = lookup(local.git_author, "name", null)
    GitAuthorEmail  = lookup(local.git_author, "email", null)
    GitOrganization = local.git_org
    GitRepository   = local.git_repo
    GitRevision     = try(local.git_commit.revision, null)
    GitTimestamp    = local.git_updated
  } : {})

  // Tags relating to feature builds and deployments
  env_tags = merge(local.current_build_name != null ? {
    Build = local.current_build_name
    } : {}, local.current_deployment_name != null ? {
    Deployment = local.current_deployment_name
  } : {})

  // Standard tags to insert
  standard_tags = merge({
    Account     = local.account_name
    Environment = local.current_env_name
  }, local.account_tags, local.env_tags, local.actor_tags, local.git_tags)

  // Remove any workspace prefix values that are null
  prefix_tags = {
    for k, v in local.workspace_prefix_map :
    k => v if v != null
  }

  // Compile all tags together
  tags = merge(
    // Default tags
    local.standard_tags,

    // Tags from custom workspace prefix
    local.prefix_tags,

    // Tags passed into module instance
    var.tags,
  )
}
