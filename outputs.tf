# --- DCIM Outputs ---

output "region_ids" {
  description = "Map of region names to their NetBox IDs"
  value       = { for k, v in netbox_region.regions : k => v.id }
}

output "tenant_group_ids" {
  description = "Map of tenant group names to their NetBox IDs"
  value       = { for k, v in netbox_tenant_group.groups : k => v.id }
}

output "tenant_ids" {
  description = "Map of tenant keys to their NetBox IDs"
  value       = { for k, v in netbox_tenant.tenants : k => v.id }
}

output "site_ids" {
  description = "Map of site keys to their NetBox IDs"
  value       = { for k, v in netbox_site.sites : k => v.id }
}

output "location_ids" {
  description = "Map of location unique IDs to their NetBox IDs"
  value       = { for k, v in netbox_location.locations : k => v.id }
}

output "rack_ids" {
  description = "Map of rack keys to their NetBox IDs"
  value       = { for k, v in netbox_rack.racks : k => v.id }
}

output "device_role_ids" {
  description = "Map of device role names to their NetBox IDs"
  value       = { for k, v in netbox_device_role.roles : k => v.id }
}

output "platform_ids" {
  description = "Map of platform names to their NetBox IDs"
  value       = { for k, v in netbox_platform.platforms : k => v.id }
}

output "device_ids" {
  description = "Map of device keys to their NetBox IDs"
  value       = { for k, v in netbox_device.devices : k => v.id }
}

output "virtual_chassis_ids" {
  description = "Map of Virtual Chassis keys to their NetBox IDs"
  value       = { for k, v in netbox_virtual_chassis.vcs : k => v.id }
}

output "device_primary_ip_ids" {
  description = "Map of interface keys to their netbox_device_primary_ip resource IDs"
  value       = { for k, v in netbox_device_primary_ip.primary_ips : k => v.id }
}

output "vm_primary_ip_ids" {
  description = "Map of interface keys to their netbox_primary_ip resource IDs"
  value       = { for k, v in netbox_primary_ip.vm_primary_ips : k => v.id }
}

output "device_interface_ids" {
  description = "Map of device interface keys to their NetBox IDs"
  value       = { for k, v in netbox_device_interface.interfaces : k => v.id }
}

output "cluster_type_ids" {
  description = "Map of cluster type names to their NetBox IDs"
  value       = { for k, v in netbox_cluster_type.cluster_types : k => v.id }
}

output "cluster_ids" {
  description = "Map of cluster keys to their NetBox IDs"
  value       = { for k, v in netbox_cluster.clusters : k => v.id }
}

output "virtual_machine_ids" {
  description = "Map of virtual machine keys to their NetBox IDs"
  value       = { for k, v in netbox_virtual_machine.vms : k => v.id }
}

output "vm_interface_ids" {
  description = "Map of VM interface keys to their NetBox IDs"
  value       = { for k, v in netbox_interface.vm_interfaces : k => v.id }
}

# --- IPAM Outputs ---

output "rir_ids" {
  description = "Map of RIR names to their NetBox IDs"
  value       = { for k, v in netbox_rir.rirs : k => v.id }
}

output "aggregate_ids" {
  description = "Map of aggregate keys to their NetBox IDs"
  value       = { for k, v in netbox_aggregate.aggregates : k => v.id }
}

output "vrf_ids" {
  description = "Map of VRF tenant names to their NetBox IDs"
  value       = { for k, v in netbox_vrf.vrfs : k => v.id }
}

output "vlan_ids" {
  description = "Map of VLAN keys to their NetBox IDs"
  value       = { for k, v in netbox_vlan.vlans : k => v.id }
}

output "prefix_ids" {
  description = "Map of prefix keys to their NetBox IDs"
  value       = { for k, v in netbox_prefix.prefixes : k => v.id }
}

output "device_ip_ids" {
  description = "Map of device IP address keys to their NetBox IDs"
  value       = { for k, v in netbox_ip_address.device_ips : k => v.id }
}

output "vm_ip_ids" {
  description = "Map of VM IP address keys to their NetBox IDs"
  value       = { for k, v in netbox_ip_address.vm_ips : k => v.id }
}

output "all_ip_ids" {
  description = "Merged map of all IP address keys (device and VM) to their NetBox IDs"
  value = merge(
    { for k, v in netbox_ip_address.device_ips : k => v.id },
    { for k, v in netbox_ip_address.vm_ips : k => v.id }
  )
}

# --- Summary Outputs ---

output "infrastructure_summary" {
  description = "Summary of created infrastructure"
  value = {
    regions           = length(netbox_region.regions)
    tenant_groups     = length(netbox_tenant_group.groups)
    tenants           = length(netbox_tenant.tenants)
    sites             = length(netbox_site.sites)
    locations         = length(netbox_location.locations)
    racks             = length(netbox_rack.racks)
    device_roles      = length(netbox_device_role.roles)
    platforms         = length(netbox_platform.platforms)
    devices           = length(netbox_device.devices)
    virtual_chassis   = length(netbox_virtual_chassis.vcs)
    device_interfaces = length(netbox_device_interface.interfaces)
    cluster_types     = length(netbox_cluster_type.cluster_types)
    clusters          = length(netbox_cluster.clusters)
    virtual_machines  = length(netbox_virtual_machine.vms)
    vm_interfaces     = length(netbox_interface.vm_interfaces)
    rirs              = length(netbox_rir.rirs)
    aggregates        = length(netbox_aggregate.aggregates)
    vrfs              = length(netbox_vrf.vrfs)
    vlans             = length(netbox_vlan.vlans)
    prefixes          = length(netbox_prefix.prefixes)
    ip_addresses      = length(netbox_ip_address.device_ips) + length(netbox_ip_address.vm_ips)
  }
}
