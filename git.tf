data "git_repository" "this" {
  count = var.track_git ? 1 : 0

  directory = path.root
}

locals {
  // Only load commit data if tracking is enabled and there's
  // at least one commit in the repository
  git_check_commit = lookup(element(flatten([data.git_repository.this.*, {}]), 0), "sha1", null) != null
}

data "git_commit" "this" {
  count = local.git_check_commit ? 1 : 0

  directory = path.root
  revision  = data.git_repository.this.0.sha1
}

data "git_remotes" "this" {
  count = var.track_git ? 1 : 0

  directory = data.git_repository.this.0.directory
}

locals {
  // Regex for parsing URLs
  url_regex = "(?:(?P<scheme>[^:/?#]+):)?(?://(?P<authority>[^/?#]*))?(?P<path>[^?#]*)(?:\\?(?P<query>[^#]*))?(?:#(?P<fragment>.*))?"

  // Get the remotes for the git repo
  git_remotes = element(flatten([data.git_remotes.this.*, {}]), 0)

  // Get and parse the origin remote
  git_origin_url = regex(local.url_regex, try(local.git_remotes.remotes.origin.urls.0, ""))

  // Extract the parts of the remote url path
  git_origin_paths = compact(split("/", trimsuffix(trimprefix(local.git_origin_url.path, "/"), ".git")))

  // Get the current commit for the git repo
  git_commit = element(flatten([data.git_commit.this.*, {}]), 0)

  // Get the organization from the repo path
  git_org = try(local.git_origin_paths[0], null)

  // Get the repository from the repo path
  git_repo = try(local.git_origin_paths[length(local.git_origin_paths) - 1], null)

  // Get the commit author
  git_author = try(local.git_commit.author, {})

  // Get the timestamp the commit was made
  git_timestamp = lookup(local.git_author, "timestamp", null)

  git_updated = try(
    formatdate("DD/MM/YYYY hh:mm:ss", local.git_timestamp),
    local.git_timestamp,
  )
}

output "git_origin_paths" {
  value = local.git_origin_paths
}
