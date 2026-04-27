# --- Virtualization: Cluster Types ---
# Cluster types represent the hypervisor platform (e.g. "VMware vSphere", "Proxmox VE").
# They are the top of the virtualization hierarchy and must exist before clusters can
# be created. Defaults are defined in variables.tf and can be overridden in terraform.tfvars.
resource "netbox_cluster_type" "cluster_types" {
  for_each = toset(var.cluster_types)
  name     = each.value
}

# --- Virtualization: Clusters ---
# A cluster represents a physical grouping of hypervisor hosts (e.g. a vSphere cluster
# or a Proxmox node group). Each cluster belongs to a cluster type and is scoped to a
# site from infrastructure_map.
resource "netbox_cluster" "clusters" {
  for_each = var.clusters_map

  name             = each.value.name
  cluster_type_id  = netbox_cluster_type.cluster_types[each.value.type].id
  site_id          = netbox_site.sites[each.value.site].id
  description      = each.value.description != null ? each.value.description : null
}

# --- Virtualization: Virtual Machines ---
# Virtual machines are assigned to a cluster. Optionally, a role and platform can be
# assigned — these reuse the same netbox_device_role and netbox_platform resources
# already created in dcim.tf, so no duplication is needed.
resource "netbox_virtual_machine" "vms" {
  for_each = var.virtual_machines_map

  name       = each.value.name
  cluster_id = netbox_cluster.clusters[each.value.cluster].id
  status     = each.value.status

  # Role and platform are optional. When provided they must match values
  # already present in var.device_roles and var.platforms respectively.
  role_id     = each.value.role != null ? netbox_device_role.roles[each.value.role].id : null
  platform_id = each.value.platform != null ? netbox_platform.platforms[each.value.platform].id : null

  # Hardware sizing — all optional
  vcpus     = each.value.vcpus != null ? each.value.vcpus : null
  memory_mb = each.value.memory_mb != null ? each.value.memory_mb : null
  disk_size_mb   = each.value.disk_mb != null ? each.value.disk_mb : null

  description = each.value.description != null ? each.value.description : null

  depends_on = [
    netbox_cluster.clusters,
    netbox_device_role.roles,
    netbox_platform.platforms
  ]
}

resource "netbox_interface" "vm_interfaces" {
  for_each = var.vm_interfaces_map

  name               = each.value.name
  virtual_machine_id = netbox_virtual_machine.vms[each.value.virtual_machine].id
  enabled            = each.value.enabled

  depends_on = [netbox_virtual_machine.vms]
}

# --- Virtualization: Set Primary IPv4 on Virtual Machines ---
# Uses the dedicated netbox_primary_ip resource to associate a primary IPv4
# address with a virtual machine. Only runs for IPs flagged with
# primary_ip4 = true and interface_type = "vm".
resource "netbox_primary_ip" "vm_primary_ips" {
  for_each = {
    for ip_key, ip_val in var.ip_addresses_map : ip_val.interface_key => ip_key
    if ip_val.primary_ip4 == true && ip_val.interface_type == "vm"
  }

  virtual_machine_id = netbox_virtual_machine.vms[var.vm_interfaces_map[each.key].virtual_machine].id
  ip_address_id      = netbox_ip_address.vm_ips[each.value].id

  depends_on = [netbox_ip_address.vm_ips]
}
