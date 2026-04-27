# --- IPAM: RIRs and Aggregates ---
resource "netbox_rir" "rirs" {
  for_each = var.rirs
  name     = each.value.name
}

resource "netbox_aggregate" "aggregates" {
  for_each = var.aggregates
  prefix   = each.value.prefix
  rir_id   = netbox_rir.rirs[each.value.rir].id
}

# --- IPAM: VRFs ---
resource "netbox_vrf" "vrfs" {
  for_each  = toset([for s in var.infrastructure_map : s.tenant_name])
  name      = "VRF-${each.value}"
  tenant_id = netbox_tenant.tenants[each.value].id
}

# --- IPAM: VLANs ---
resource "netbox_vlan" "vlans" {
  for_each = var.vlans

  name        = each.value.name
  vid         = each.value.vid
  description = each.value.description
  site_id     = netbox_site.sites[each.value.site].id
  status      = each.value.status
}

# --- IPAM: Prefixes ---
resource "netbox_prefix" "prefixes" {
  for_each = var.vlans

  prefix      = each.value.prefix
  description = each.value.description
  status      = each.value.status
  site_id     = netbox_site.sites[each.value.site].id
  vlan_id     = netbox_vlan.vlans[each.key].id

  # Optionally assign to VRF (uncomment and adjust to enable)
  # vrf_id = netbox_vrf.vrfs[var.infrastructure_map[each.value.site].tenant_name].id
}

# --- IPAM: IP Addresses on Physical Device Interfaces ---
# Handles IPs where interface_type = "device".
# Uses object_type "dcim.interface" to associate with a netbox_device_interface resource.
resource "netbox_ip_address" "device_ips" {
  for_each = { for k, v in var.ip_addresses_map : k => v if v.interface_type == "device" }

  ip_address  = each.value.address
  status      = each.value.status
  dns_name    = each.value.dns_name != null ? each.value.dns_name : null
  description = each.value.description != null ? each.value.description : null

  # Links this IP to a physical device interface.
  # object_type must be "dcim.interface" for physical device ports.
  object_type  = "dcim.interface"
  interface_id = netbox_device_interface.interfaces[each.value.interface_key].id

  depends_on = [netbox_device_interface.interfaces]
}

# --- IPAM: IP Addresses on Virtual Machine Interfaces ---
# Handles IPs where interface_type = "vm".
# Uses object_type "virtualization.vminterface" to associate with a VM interface resource.
resource "netbox_ip_address" "vm_ips" {
  for_each = { for k, v in var.ip_addresses_map : k => v if v.interface_type == "vm" }

  ip_address  = each.value.address
  status      = each.value.status
  dns_name    = each.value.dns_name != null ? each.value.dns_name : null
  description = each.value.description != null ? each.value.description : null

  # Links this IP to a virtual machine interface.
  # object_type must be "virtualization.vminterface" for VM ports.
  object_type  = "virtualization.vminterface"
  interface_id = netbox_interface.vm_interfaces[each.value.interface_key].id
  depends_on   = [netbox_interface.vm_interfaces]
}
