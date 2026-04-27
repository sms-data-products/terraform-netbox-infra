# --- Data Sources ---

# Data source to look up device types by model name
# This allows dynamic lookup instead of hardcoding device_type_id
data "netbox_device_type" "device_types" {
  for_each = toset([for d in var.devices_map : d.device_type])

  model = each.value
}

# Optional: Data source for manufacturers if needed
# Uncomment if you need to reference manufacturers
# data "netbox_manufacturer" "manufacturers" {
#   for_each = toset(var.manufacturers)
#   name     = each.value
# }

# Optional: Data source to look up existing tenants
# Useful if some tenants already exist in NetBox
# data "netbox_tenant" "existing_tenants" {
#   for_each = var.existing_tenant_names
#   name     = each.value
# }

