locals {
  # Flattens the locations list from each site into a single map
  flat_locations = flatten([
    for site_key, site_data in var.infrastructure_map : [
      for loc in site_data.locations : {
        site_key      = site_key
        location_name = loc
        unique_id     = "${site_key}_${loc}"
      }
    ]
  ])
}

# --- DCIM: Global Lists (Platforms & Roles) ---
resource "netbox_platform" "platforms" {
  for_each = toset(var.platforms)
  name     = each.value
}

resource "netbox_device_role" "roles" {
  for_each = toset(var.device_roles)
  name     = each.value
  # Generating a consistent color based on the name string
  color_hex = substr(md5(each.value), 0, 6)
}

# --- DCIM: Tenancy & Regions ---
resource "netbox_tenant_group" "groups" {
  for_each = toset([for s in var.infrastructure_map : s.tenant_group])
  name     = each.value
}

resource "netbox_tenant" "tenants" {
  for_each = {
    for k, v in var.infrastructure_map : v.tenant_name => v...
  }
  name     = each.key
  group_id = netbox_tenant_group.groups[each.value[0].tenant_group].id
}

resource "netbox_region" "regions" {
  for_each = toset([for s in var.infrastructure_map : s.region])
  name     = each.value
}

# --- DCIM: Sites ---
resource "netbox_site" "sites" {
  for_each  = var.infrastructure_map
  name      = each.value.site_name
  status    = each.value.status
  region_id = netbox_region.regions[each.value.region].id
  tenant_id = netbox_tenant.tenants[each.value.tenant_name].id
}

# --- DCIM: Locations ---
resource "netbox_location" "locations" {
  for_each = { for l in local.flat_locations : l.unique_id => l }

  name    = each.value.location_name
  site_id = netbox_site.sites[each.value.site_key].id
}

# --- DCIM: Racks ---
resource "netbox_rack" "racks" {
  for_each = var.racks_map

  name        = each.value.name
  status      = each.value.status
  site_id     = netbox_site.sites[each.value.site].id
  location_id = netbox_location.locations["${each.value.site}_${each.value.location}"].id
  u_height    = each.value.u_height
  width       = each.value.width  
}

# --- DCIM: Virtual Chassis ---
# Creates a Virtual Chassis container for devices flagged with has_vc
resource "netbox_virtual_chassis" "vcs" {
  for_each = { for k, v in var.devices_map : k => v if v.has_vc }
  name     = "${each.value.name}-VC"
}

# --- DCIM: Devices ---
resource "netbox_device" "devices" {
  for_each = var.devices_map

  name        = each.value.name
  role_id     = netbox_device_role.roles[each.value.role].id
  platform_id = netbox_platform.platforms[each.value.platform].id

  # Site is derived from the rack's site assignment for data integrity
  site_id = netbox_site.sites[var.racks_map[each.value.rack].site].id
  rack_id = netbox_rack.racks[each.value.rack].id
  location_id = netbox_location.locations["${var.racks_map[each.value.rack].site}_${var.racks_map[each.value.rack].location}"].id

  # Use data source to lookup device type ID by model name
  device_type_id = data.netbox_device_type.device_types[each.value.device_type].id

  # Rack unit position — optional; enables rack diagram rendering in NetBox
  rack_position = each.value.rack_position != null ? each.value.rack_position : null
  rack_face     = each.value.rack_face != null ? each.value.rack_face : null  

  # Assign to Virtual Chassis if applicable
  virtual_chassis_id     = each.value.has_vc ? netbox_virtual_chassis.vcs[each.key].id : null
  virtual_chassis_master = each.value.has_vc ? true : null
  virtual_chassis_position = each.value.has_vc ? 1 : null
}

# --- DCIM: Modules ---
resource "netbox_module" "modules" {
  for_each = { for k, v in var.devices_map : k => v if v.module_bay_id != null }

  device_id      = netbox_device.devices[each.key].id
  module_bay_id  = each.value.module_bay_id
  module_type_id = each.value.module_type_id
  status         = each.value.module_status != null ? each.value.module_status : "active"
}
# --- DCIM: Device Interfaces ---
# Creates physical interfaces on devices and optionally assigns an untagged (access) VLAN.
# The 'type' field must use NetBox interface type slugs, e.g.:
#   "1000base-t"     - 1GbE copper
#   "10gbase-x-sfpp" - 10GbE SFP+
#   "25gbase-x-sfp28"- 25GbE SFP28
#   "40gbase-x-qsfpp"- 40GbE QSFP+
#   "100gbase-x-qsfp28" - 100GbE QSFP28
#   "virtual"        - Virtual/logical interface
resource "netbox_device_interface" "interfaces" {
  for_each = var.device_interfaces_map

  name      = each.value.name
  device_id = netbox_device.devices[each.value.device].id
  type      = each.value.type
  enabled   = each.value.enabled

  # Set interface mode only when explicitly provided
  mode = each.value.mode != null ? each.value.mode : null

  # Assign an untagged VLAN when mode is "access" and a vlan_key is provided.
  # The vlan_key must reference a key in var.vlans.
  untagged_vlan = (
    each.value.mode == "access" && each.value.vlan_key != null
    ? netbox_vlan.vlans[each.value.vlan_key].id
    : null
  )

  depends_on = [netbox_device.devices, netbox_vlan.vlans]
}

# --- DCIM: Set Primary IPv4 on Devices ---
# Uses the dedicated netbox_device_primary_ip resource to associate a primary IPv4
# address with a device. This is a separate resource from netbox_device and only
# runs for IPs flagged with primary_ip4 = true and interface_type = "device".
resource "netbox_device_primary_ip" "primary_ips" {
  for_each = {
    for ip_key, ip_val in var.ip_addresses_map : ip_val.interface_key => ip_key
    if ip_val.primary_ip4 == true && ip_val.interface_type == "device"
  }

  device_id     = netbox_device.devices[var.device_interfaces_map[each.key].device].id
  ip_address_id = netbox_ip_address.device_ips[each.value].id

  depends_on = [netbox_ip_address.device_ips]
}
