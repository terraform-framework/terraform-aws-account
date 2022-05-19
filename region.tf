data "aws_region" "this" {
  // Get current region
}

// Lookup availability zones by state
data "aws_availability_zones" "this" {
  state = var.zone_state
}
