# terraform-aws-account

A Terraform module that acts as a foundational data layer for multi-account, multi-environment AWS deployments. Rather than provisioning infrastructure itself, this module normalises AWS account data, parses workspace context, enforces naming conventions, and compiles a unified tag map — outputs that consuming Terraform configurations use to build resources consistently across accounts and environments.

## Table of Contents

- [How It Works](#how-it-works)
- [Configuration Files](#configuration-files)
- [Workspace Naming Convention](#workspace-naming-convention)
- [Naming System](#naming-system)
- [Tagging System](#tagging-system)
- [Actor Tracking](#actor-tracking)
- [Git Tracking](#git-tracking)
- [Providers](#providers)
- [Inputs](#inputs)
- [Outputs](#outputs)
- [Usage](#usage)

---

## How It Works

The module composes several independent subsystems that each contribute data to the final outputs:

```
┌─────────────────────────────────────────────────────────┐
│                  Configuration Loading                   │
│  Local YAML/JSON files  +  Remote HTTP endpoint          │
│  Merged per-account config keyed by account ID           │
└───────────────────┬─────────────────────────────────────┘
                    │ account config
        ┌───────────┼────────────────────┐
        ▼           ▼                    ▼
  ┌──────────┐ ┌──────────┐       ┌──────────────┐
  │ Account  │ │ Environ- │       │  Workspace   │
  │  name,   │ │  ments,  │       │  Parsing     │
  │  domain, │ │  networks│       │  env/build/  │
  │  CIDRs   │ │  domains │       │  deployment  │
  └──────────┘ └──────────┘       └──────────────┘
        │           │                    │
        └───────────┼────────────────────┘
                    ▼
        ┌───────────────────────┐
        │   Naming & Tagging    │
        │  Templates → formats  │
        │  Tags aggregated from │
        │  all sources          │
        └───────────────────────┘
                    │
                    ▼
              Module Outputs
```

### Subsystems

| File | Responsibility |
|------|---------------|
| `config.tf` | Loads and merges local YAML/JSON and remote HTTP configuration |
| `account.tf` | Extracts the current account's name and config block |
| `workspace.tf` | Parses the Terraform workspace name into prefix, environment, build, and deployment components |
| `environments.tf` | Normalises environment definitions; resolves the current environment and its network config |
| `naming.tf` | Template engine for resource names and `Name` tag values |
| `tags.tf` | Aggregates tags from all sources into a single map |
| `actor.tf` | Identifies the IAM user or role running Terraform from the caller ARN |
| `git.tf` | Optionally reads the local git repository for commit and author metadata |
| `helpers.tf` | Boolean helper map for conditional logic in consuming configurations |
| `root.tf` | Resolves the root domain for the account |
| `region.tf` | Exposes current region and filtered availability zones |
| `partition.tf` | Exposes the AWS partition (commercial, GovCloud, China, etc.) |

---

## Configuration Files

Configuration is loaded from one or both sources. When both are provided, **local configuration takes precedence** over remote.

### Local Files

Set `local_config_path` to a directory containing YAML or JSON files. Optionally set `local_config_subpath` to a path pattern within that directory (e.g. `{environment}/{region}`) — this creates named capture groups that are automatically extracted as grouping metadata.

```
config/
├── production/
│   └── 123456789012.yaml
└── staging/
    └── 987654321098.yaml
```

```hcl
module "account" {
  source               = "path/to/terraform-aws-account"
  local_config_path    = "${path.module}/config"
  local_config_subpath = "{environment}"
}
```

### Remote HTTP Endpoint

Set `remote_config_url` to an HTTP endpoint that returns a JSON object. Supply `remote_config_headers` (marked sensitive) for authenticated endpoints such as internal APIs or secret managers.

```hcl
module "account" {
  source                = "path/to/terraform-aws-account"
  remote_config_url     = "https://config.internal/accounts"
  remote_config_headers = { "Authorization" = "Bearer ${var.api_token}" }
}
```

### Configuration Schema

Files are keyed by **AWS account ID**. All sections are optional.

```yaml
"123456789012":
  account:
    name: production               # Friendly name (defaults to account ID)
    domain: example.com            # Root domain (defaults to "{name}.local")
    cidr_blocks:                   # Account-level CIDR ranges
      - 10.0.0.0/8
    tags:                          # Account-level tags applied to everything
      CostCenter: platform
    remote_state:                  # Arbitrary remote state backend config
      bucket: my-tfstate-bucket
      dynamodb_table: my-lock-table

  environments:
    prod:
      cidr_blocks: [10.1.0.0/16]
      subnets:
        public:  [10.1.1.0/24]
        private: [10.1.2.0/24]
      custom:                      # Arbitrary per-environment data
        rds_instance_class: db.r6g.large

    # Regional environments: network config is scoped per AWS region
    prod:
      regional: true
      eu-west-1:
        cidr_blocks: [10.2.0.0/16]
        subnets:
          public:  [10.2.1.0/24]
          private: [10.2.2.0/24]

  naming:                          # Override naming conventions per account
    resource_name_separator: "-"
    resource_name_template: "{prefix}{sep}{build}{sep}{name}{sep}{suffix}"
    tag_name_separator: "/"
    tag_name_template: "{prefix}{sep}{build}{sep}{name}{sep}{suffix}"

  workspace:                       # Override workspace parsing per account
    prefix_format: "[a-zA-Z0-9-]+"
    prefix_separator: "-"
    build_separator: "_"
    deployment_separator: ":"

  grouping:                        # Arbitrary grouping metadata → tags + `ids` output
    department: engineering
    product: platform
```

---

## Workspace Naming Convention

The Terraform workspace name is parsed by a configurable regex to extract up to four components. This enables a single module to serve multiple tiers of environment management without separate Terraform root modules.

### Default Format

```
[prefix-]environment[_build][:deployment]
```

| Component | Separator | Default Regex | Description |
|-----------|-----------|---------------|-------------|
| `prefix` | `-` (prefix separator) | `[a-zA-Z0-9-]+` | Optional arbitrary prefix; any named capture groups become tags |
| `environment` | — | `[a-zA-Z0-9]+` | Required; matches a key in `environments` config |
| `build` | `_` (build separator) | `[a-zA-Z0-9-]+` | Optional feature build name |
| `deployment` | `:` (deployment separator) | `[a-zA-Z0-9]+` | Optional deployment instance name |

### Examples

| Workspace | `prefix` | `environment` | `build` | `deployment` |
|-----------|----------|---------------|---------|--------------|
| `prod` | — | `prod` | — | — |
| `team-prod` | `team` | `prod` | — | — |
| `prod_feature123` | — | `prod` | `feature123` | — |
| `prod_feature123:blue` | — | `prod` | `feature123` | `blue` |
| `team-prod_feature123:blue` | `team` | `prod` | `feature123` | `blue` |

All separators and format regexes are configurable via variables or the `workspace` block in config — variable values take precedence over config values.

The parsed workspace components are available via the `workspace`, `env`, `build`, and `deployment` outputs, and feed into all naming and tagging logic automatically.

---

## Naming System

The module provides a template-based naming engine for both resource names and `Name` tag values, keeping them consistent across all resources in a consuming configuration.

### Template Tokens

Templates support the following tokens. Tokens are resolved from the current context and tags.

| Token | Value |
|-------|-------|
| `{environment}` | Current environment name |
| `{build}` | Current build name (empty if not a build workspace) |
| `{deployment}` | Current deployment name (empty if not a deployment workspace) |
| `{account}` | Account friendly name |
| `{region}` | AWS region name |
| `{prefix}` | Computed prefix (result of the prefix template) |
| `{suffix}` | Computed suffix (result of the suffix template) |
| `{name}` | Placeholder for the resource-specific name (rendered as `%s`) |
| `{sep}` | The configured separator character |

Any tag key (lowercased, spaces replaced with `_`) is also available as a token, which allows grouping metadata to flow into names automatically.

### Resource Names

Resource names are lowercased. Defaults:

| Setting | Default |
|---------|---------|
| Separator | `-` |
| Prefix template | `{environment}` |
| Suffix template | `{deployment}` |
| Name template | `{prefix}{sep}{build}{sep}{name}{sep}{suffix}` |

The `resource_name.format` output contains a `printf`-style format string with `%s` as the placeholder for the specific resource name:

```hcl
name = format(module.account.resource_name.format, "my-bucket")
# → "prod-feature123-my-bucket-blue"
```

### Tag Names (`Name` tag)

Tag names are uppercased. Defaults:

| Setting | Default |
|---------|---------|
| Separator | `/` |
| Prefix template | `{account}{sep}{environment}` |
| Suffix template | `{deployment}` |
| Name template | `{prefix}{sep}{build}{sep}{name}{sep}{suffix}` |

```hcl
tags = merge(module.account.tags, {
  Name = format(module.account.tag_name.format, "My Bucket")
})
# → "PRODUCTION/PROD/FEATURE123/MY BUCKET/BLUE"
```

The `resource_tag_codes` variable accepts a map of substitutions applied during tag name construction, enabling abbreviations (e.g. `production → prod`) without affecting resource names.

### Domain Names

Environments each get a computed fully-qualified domain name. Defaults:

- **Domain template**: `{environment}` → `prod.example.com`
- **Subdomain template**: `{deployment}.{build}` → `blue.feature123.prod.example.com`

Both are available from the `env`, `build`, and `deployment` outputs.

---

## Tagging System

The module compiles a single `tags` output map from multiple sources in the following precedence order (later sources override earlier ones):

| Priority | Source | Example Tags |
|----------|--------|-------------|
| 1 (base) | Standard | `Region`, `Account`, `Environment` |
| 2 | Account config `tags` block | `CostCenter`, `Owner` |
| 3 | Workspace build/deployment | `Build`, `Deployment` |
| 4 | Actor tracking | `CreatedActor`, `UpdatedActor` |
| 5 | Git tracking | `GitOrganization`, `GitRepository`, `GitRevision`, `GitTimestamp`, `GitAuthorName`, `GitAuthorEmail` |
| 6 | Config `grouping` block | `Department`, `Product` |
| 7 | Workspace prefix capture groups | Any named groups in the prefix regex |
| 8 (top) | `tags` variable | Any user-supplied tags |

Apply to all resources by spreading the output:

```hcl
resource "aws_s3_bucket" "example" {
  bucket = format(module.account.resource_name.format, "data")
  tags   = merge(module.account.tags, {
    Name = format(module.account.tag_name.format, "Data Bucket")
  })
}
```

---

## Actor Tracking

When `track_actor = true` (the default), the module parses the caller's IAM ARN from `aws_caller_identity` to identify who is running Terraform.

- For **IAM users**: the username is extracted and formatted (dot-separated names like `jane.doe` become `Jane Doe`)
- For **assumed roles** (STS): the role name is used as the actor name; the session name is captured separately in `actor.session`

The `actor` output exposes `name`, `path`, and `session`. Actor information flows into tags via:

- `track_actor_created = true` (default) → adds `CreatedActor` tag
- `track_actor_updated = true` (default: false) → adds `UpdatedActor` tag

---

## Git Tracking

When `track_git = true`, the module reads the local git repository at `path.root` using the `metio/git` provider.

Collected data:

| Data | Variable | Output field |
|------|----------|-------------|
| Remote organisation | `track_git = true` | `git.organization` |
| Repository name | `track_git = true` | `git.repository` |
| Commit hash | `track_git_commit = true` | `git.revision` |
| Commit timestamp | `track_git_commit = true` | `git.timestamp` |
| Author name | `track_git_actor = true` | `git.author.name` |
| Author email | `track_git_actor = true` | `git.author.email` |

The organisation and repository name are parsed from the `origin` remote URL and support both HTTPS and SSH remote formats.

When `track_git_commit = true`, the tags `GitRevision` and `GitTimestamp` are added. When `track_git_actor = true`, `GitAuthorName` and `GitAuthorEmail` are added.

---

## Providers

| Provider | Source | Notes |
|----------|--------|-------|
| AWS | `hashicorp/aws` | Required; must be configured by the consuming module |
| HTTP | `hashicorp/http` | Used when `remote_config_url` is set |
| Git | `metio/git` | Used when `track_git = true` |

---

## Inputs

### Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `local_config_path` | `string` | `null` | Path to a directory containing YAML or JSON config files |
| `local_config_subpath` | `string` | `null` | Subpath pattern within `local_config_path`; supports `{token}` placeholders that become named grouping captures |
| `remote_config_url` | `string` | `null` | URL returning a JSON configuration object |
| `remote_config_headers` | `map(string)` | `{}` | HTTP headers for `remote_config_url` (sensitive) |

### Environment

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `environment_override` | `string` | `null` | Explicitly set the environment instead of deriving it from the workspace name |
| `zone_state` | `string` | `null` | Filter availability zones by state (e.g. `"available"`) |
| `workspace_source` | `string` | `null` | Override the workspace string to parse instead of `terraform.workspace` |

### Workspace Parsing

All workspace variables override config-file settings, which override built-in defaults.

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `workspace_prefix_format` | `string` | `[a-zA-Z0-9-]+` | Regex for the workspace prefix segment |
| `workspace_env_format` | `string` | `[a-zA-Z0-9]+` | Regex for the environment segment |
| `workspace_build_format` | `string` | `[a-zA-Z0-9-]+` | Regex for the build segment |
| `workspace_deployment_format` | `string` | `[a-zA-Z0-9]+` | Regex for the deployment segment |
| `workspace_prefix_separator` | `string` | `-` | Separator between prefix and environment |
| `workspace_build_separator` | `string` | `_` | Separator between environment and build |
| `workspace_deployment_separator` | `string` | `:` | Separator between build and deployment |

### Naming

All naming variables override config-file settings, which override built-in defaults.

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `resource_name_separator` | `string` | `-` | Separator used in resource names |
| `resource_name_prefix_template` | `string` | `{environment}` | Template for the resource name prefix |
| `resource_name_suffix_template` | `string` | `{deployment}` | Template for the resource name suffix |
| `resource_name_template` | `string` | `{prefix}{sep}{build}{sep}{name}{sep}{suffix}` | Full resource name template |
| `tag_name_separator` | `string` | `/` | Separator used in tag names |
| `tag_name_prefix_template` | `string` | `{account}{sep}{environment}` | Template for the tag name prefix |
| `tag_name_suffix_template` | `string` | `{deployment}` | Template for the tag name suffix |
| `tag_name_template` | `string` | `{prefix}{sep}{build}{sep}{name}{sep}{suffix}` | Full tag name template |
| `domain_template` | `string` | `{environment}` | Template for environment subdomain |
| `subdomain_template` | `string` | `{deployment}.{build}` | Template for build/deployment subdomain |
| `resource_tag_codes` | `map(string)` | `{}` | Substitution map applied to tag name values (e.g. abbreviations) |
| `tags` | `map(string)` | `{}` | Additional tags merged into all resources |

### Tracking

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `track_actor` | `bool` | `true` | Enable IAM actor identification |
| `track_actor_created` | `bool` | `true` | Add `CreatedActor` tag |
| `track_actor_updated` | `bool` | `false` | Add `UpdatedActor` tag |
| `track_git` | `bool` | `false` | Enable git repository tracking |
| `track_git_actor` | `bool` | `false` | Add `GitAuthorName` and `GitAuthorEmail` tags |
| `track_git_commit` | `bool` | `false` | Add `GitRevision` and `GitTimestamp` tags |

---

## Outputs

| Output | Type | Description |
|--------|------|-------------|
| `id` | `string` | AWS account ID of the current caller |
| `name` | `string` | Friendly account name from config, or account ID if not configured |
| `remote_state` | `map` | Arbitrary remote state backend config from the account config block |
| `actor` | `object` | `name`, `path`, and `session` of the current IAM user or role |
| `env` | `object` | Current environment: `name`, `build`, `deployment`, `domain`, `network` (CIDRs + subnets), `custom` |
| `envs` | `map` | All configured environments, each with the same shape as `env` |
| `build` | `object` | Current build: `name` and scoped `domain` |
| `deployment` | `object` | Current deployment: `name` and scoped `domain` |
| `is` | `object` | Boolean helpers — see below |
| `ids` | `map` | Map of `account_name → account_id` for accounts sharing the same grouping |
| `resource_name` | `object` | `format` (printf-style), `prefix`, `suffix`, `separator` for resource names |
| `tag_name` | `object` | `format` (printf-style), `prefix`, `suffix`, `separator` for `Name` tags |
| `tags` | `map(string)` | Compiled tag map to apply to all resources |
| `region` | `object` | `name`, `description`, and `zones` (list of AZ names) |
| `root` | `object` | `domain` (root account domain) and `cidr_blocks` |
| `workspace` | `object` | `prefix` and `separator` for constructing remote state data sources |
| `groups` | `map` | Current account's grouping metadata |
| `partition` | `string` | AWS partition identifier (`aws`, `aws-us-gov`, `aws-cn`, etc.) |
| `git` | `object` | `organization`, `repository`, `revision`, `timestamp`, `author.name`, `author.email`; `null` if tracking disabled |

### The `is` Helper Map

The `is` output provides boolean values for conditional resource provisioning without requiring the consumer to re-implement account/environment lookup logic.

```hcl
# Is the current account the "production" account?
module.account.is.account.production  # true / false
module.account.is.account.unknown     # true if account not in config

# Is the current environment "prod"?
module.account.is.env.prod    # true / false
module.account.is.env.unknown # true if env not in config

# Is the current workspace a feature build or deployment?
module.account.is.build       # true / false
module.account.is.deployment  # true / false

# Grouping helpers (e.g. if config has grouping.department = "engineering")
module.account.is.department.engineering  # true / false
```

---

## Usage

### Basic

```hcl
module "account" {
  source            = "path/to/terraform-aws-account"
  local_config_path = "${path.module}/config"
}

resource "aws_s3_bucket" "data" {
  bucket = format(module.account.resource_name.format, "data")

  tags = merge(module.account.tags, {
    Name = format(module.account.tag_name.format, "Data Bucket")
  })
}
```

### With Remote Config and Git Tracking

```hcl
module "account" {
  source = "path/to/terraform-aws-account"

  remote_config_url     = "https://config.internal/accounts"
  remote_config_headers = { "Authorization" = "Bearer ${var.config_token}" }

  track_git        = true
  track_git_commit = true
}
```

### Feature Build Workspaces

```bash
# Select a feature build workspace
terraform workspace select prod_my-feature

# Or with a deployment tier
terraform workspace select prod_my-feature:blue
```

```hcl
# In configuration — conditionally deploy feature-only resources
resource "aws_route53_record" "feature" {
  count = module.account.is.build ? 1 : 0
  name  = module.account.build.domain
  # ...
}
```

### Referencing Sibling Account IDs

```hcl
# Look up the staging account ID when running in any account
# sharing the same grouping config
locals {
  staging_account_id = module.account.ids["staging"]
}
```

### Conditional Logic by Account

```hcl
resource "aws_iam_role_policy_attachment" "admin" {
  count = module.account.is.account.production ? 0 : 1
  # Only attach in non-production accounts
}
```
