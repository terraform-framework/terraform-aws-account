data "aws_region" "this" {
  // Get current region
}

// Lookup availability zones by state
data "aws_availability_zones" "this" {
  state = var.zone_state
}

output "region" {
  value = {
    name        = data.aws_region.this.name
    description = data.aws_region.this.description
    zones       = data.aws_availability_zones.this.names
  }
}
