variable "local_config_path" {
  type    = string
  default = null
}

variable "remote_config_url" {
  type    = string
  default = null
}

variable "remote_config_headers" {
  type    = map(string)
  default = {}

  // Headers could contain API keys so don't
  // include them in the output.
  sensitive = true
}

variable "workspace_override" {
  type    = string
  default = null
}

variable "zone_state" {
  type    = string
  default = null
}

variable "track_actor" {
  type    = bool
  default = true
}

variable "track_actor_created" {
  type    = bool
  default = true
}

variable "track_actor_updated" {
  type    = bool
  default = false
}

variable "tags" {
  type    = map(string)
  default = {}
}
