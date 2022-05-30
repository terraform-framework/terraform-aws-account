variable "local_config_path" {
  type    = string
  default = null

  description = "Path to a directory containing YAML or JSON config files"
}

variable "remote_config_url" {
  type    = string
  default = null

  description = "URL to an endpoint that returns an array of configuration objects in JSON format"
}

variable "remote_config_headers" {
  type    = map(string)
  default = {}

  description = "A map of header keys and values to be sent along with the request to `remote_config_url`"

  // Headers could contain API keys so don't
  // include them in the output.
  sensitive = true
}

variable "environment_override" {
  type    = string
  default = null

  description = "Allows explicitly setting the target environment rather than selecting it through the workspace. This is useful in situations where you use the `default` workspace but want to select a specific environment."
}

variable "zone_state" {
  type    = string
  default = null

  description = "The desired state of the zones to select in the current region."
}

variable "track_actor" {
  type    = bool
  default = true

  description = "Whether actor tracking is enabled or disabled."
}

variable "track_actor_created" {
  type    = bool
  default = true

  description = "Whether the name of the user or role in which AWS is invoked should have their name propogated via the CreatedActor tag"
}

variable "track_actor_updated" {
  type    = bool
  default = false

  description = "Whether the name of the user or role in which AWS is invoked should have their name propogated via the UpdatedActor tag"
}

variable "workspace_prefix_format" {
  type    = string
  default = null

  description = "Allows overriding the workspace prefix format on this instance of the module. This option takes precedence any settings set in either the locally or remotely loaded configuration."
}

variable "workspace_env_format" {
  type    = string
  default = null

  description = "Allows overriding the workspace environment format on this instance of the module. This option takes precedence any settings set in either the locally or remotely loaded configuration."
}

variable "workspace_build_format" {
  type    = string
  default = null

  description = "Allows overriding the workspace build format on this instance of the module. This option takes precedence any settings set in either the locally or remotely loaded configuration."
}

variable "workspace_deployment_format" {
  type    = string
  default = null

  description = "Allows overriding the workspace deployment format on this instance of the module. This option takes precedence any settings set in either the locally or remotely loaded configuration."
}

variable "workspace_prefix_separator" {
  type    = string
  default = null

  description = "Allows overriding the workspace prefix separator on this instance of the module. This option takes precedence any settings set in either the locally or remotely loaded configuration."
}

variable "workspace_build_separator" {
  type    = string
  default = null

  description = "Allows overriding the workspace build separator on this instance of the module. This option takes precedence any settings set in either the locally or remotely loaded configuration."
}

variable "workspace_deployment_separator" {
  type    = string
  default = null

  description = "Allows overriding the workspace deployment separator on this instance of the module. This option takes precedence any settings set in either the locally or remotely loaded configuration."
}

variable "subdomain_template" {
  type    = string
  default = null
}

variable "resource_name_separator" {
  type    = string
  default = null

  description = "Allows overriding the resource name separator on this instance of the module. This option takes precedence any settings set in either the locally or remotely loaded configuration."
}

variable "resource_name_prefix_template" {
  type    = string
  default = null

  description = "Allows overriding the resource name prefix template on this instance of the module. This option takes precedence any settings set in either the locally or remotely loaded configuration."
}

variable "resource_name_suffix_template" {
  type    = string
  default = null

  description = "Allows overriding the resource name suffix template on this instance of the module. This option takes precedence any settings set in either the locally or remotely loaded configuration."
}

variable "resource_name_template" {
  type    = string
  default = null

  description = "Allows overriding the resource name template on this instance of the module. This option takes precedence any settings set in either the locally or remotely loaded configuration."
}

variable "tag_name_separator" {
  type    = string
  default = null

  description = "Allows overriding the tag name separator on this instance of the module. This option takes precedence any settings set in either the locally or remotely loaded configuration."
}

variable "tag_name_prefix_template" {
  type    = string
  default = null

  description = "Allows overriding the tag name prefix template on this instance of the module. This option takes precedence any settings set in either the locally or remotely loaded configuration."
}

variable "tag_name_suffix_template" {
  type    = string
  default = null

  description = "Allows overriding the tag name suffix template on this instance of the module. This option takes precedence any settings set in either the locally or remotely loaded configuration."
}

variable "tag_name_template" {
  type    = string
  default = null

  description = "Allows overriding the tag name template on this instance of the module. This option takes precedence any settings set in either the locally or remotely loaded configuration."
}

variable "resource_tag_codes" {
  type    = map(string)
  default = {}

  description = "A map of key value pairs of resource name values to be replaced with in the tag values. Useful for allowing shorter names in resource values whilst allow more verbose values in tags."
}

variable "tags" {
  type    = map(string)
  default = {}

  description = "A map of key value pairs of tags to apply to all resources."
}
