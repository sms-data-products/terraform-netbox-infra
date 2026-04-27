variable "netbox_url" {
  description = "The URL of the NetBox instance."
  type        = string
}

variable "netbox_token" {
  description = "The API token for authenticating with the NetBox instance."
  type        = string
  sensitive   = true
}

variable "netbox_insecure" {
  description = "Skip TLS certificate verification (use for self-signed certs)"
  type        = bool
  default     = false
}

#### DCIM ####
 
variable "infrastructure_map" {
  description = "Map of sites with their associated hierarchy and locations"
  type = map(object({
    region       = string
    tenant_group = string
    tenant_name  = string
    site_name    = string
    status       = string
    locations    = list(string)
  }))
  default = {
    # Example:
    # "nyc_hq" = {
    #   region       = "North America"
    #   tenant_group = "Internal"
    #   tenant_name  = "Corporate IT"
    #   site_name    = "NYC-01"
    #   status       = "active"
    #   locations    = ["Server Room A", "Floor 12 IDF", "Basement DMARC"]
    # },
    # "london_hq" = {
    #   region       = "Europe"
    #   tenant_group = "Internal"
    #   tenant_name  = "Corporate IT"
    #   site_name    = "LON-01"
    #   status       = "active"
    #   locations    = ["Server Room B", "Floor 5 IDF", "Basement DMARC"]
    # }
  }
}
 
variable "device_roles" {
  description = "List of device roles to be created in NetBox."
  type        = list(string)
  default     = [
  # Network - Switching
  "Core Switch",
  "Distribution Switch",
  "Access Switch",
  "SAN Switch",
 
  # Network - Routing
  "Edge Router",
  "WAN Optimizer",
 
  # Wireless
  "Wireless Controller",
  "Wireless Access Point",
 
  # Security
  "Firewall",
  "IDS/IPS",
  "VPN Concentrator",
  "Web Proxy",
  "Email Security Gateway",
 
  # Load Balancing
  "Load Balancer",
 
  # Compute
  "Server",
  "Hypervisor Host",
  "Blade Chassis",
  "Converged Infrastructure",
 
  # Storage
  "Storage Array",
  "NAS",
  "Tape Library",
  "Backup Appliance",
 
  # Management & Console
  "Console Server",
  "Out-of-Band Management",
  "KVM Switch",
  "Environmental Monitor",
 
  # Infrastructure Services
  "DNS/DHCP Server",
  "Authentication Server",
 
  # Voice/UC
  "Voice Gateway",
  "IP Phone",
  "Conference System",
 
  # Physical Infrastructure
  "Power Distribution Unit",
  "Patch Panel",
  "Cable Management",
  "Media Converter",
  "Optical Multiplexer",
 
  # Catch-all
  "Other"
]
}
 
variable "platforms" {
  description = "List of platforms to be created in NetBox."
  type        = list(string)
  default     = [
  # Network Operating Systems - Cisco
  "Cisco IOS",
  "Cisco IOS-XE",
  "Cisco IOS-XR",
  "Cisco NX-OS",
  "Cisco ASA",
  "Cisco Firepower",
 
  # Network Operating Systems - Other Vendors
  "Arista EOS",
  "Juniper JUNOS",
  "HPE/Aruba AOS-CX",
  "Dell OS10",
  "Extreme EXOS",
  "Mikrotik RouterOS",
  "VyOS",
  "pfSense",
 
  # Wireless
  "Cisco Wireless Controller",
  "Aruba Mobility Controller",
  "Ubiquiti UniFi",
  "Ruckus SmartZone",
 
  # Security/Firewall
  "Fortinet FortiOS",
  "Palo Alto PAN-OS",
  "Check Point Gaia",
  "Cisco Firepower",
  "SonicWall SonicOS",
 
  # Load Balancers
  "F5 BIG-IP",
  "Citrix ADC",
  "HAProxy",
  "NGINX",
 
  # Linux Distributions
  "Red Hat Enterprise Linux",
  "Ubuntu Linux",
  "CentOS Linux",
  "Debian Linux",
  "Rocky Linux",
  "Amazon Linux",
 
  # Windows
  "Windows Server 2016",
  "Windows Server 2019",
  "Windows Server 2022",
  "Windows Server 2025",
 
  # Hypervisor/Virtualization
  "VMware ESXi",
  "Nutanix AOS",
  "Proxmox VE",
  "Microsoft Hyper-V",
  "KVM",
  "Citrix Hypervisor",
 
  # Out-of-Band Management
  "Dell iDRAC",
  "HP iLO",
  "Supermicro IPMI",
  "Cisco CIMC",
  "Lenovo XClarity",
 
  # Storage
  "NetApp ONTAP",
  "Dell EMC PowerStore",
  "Dell EMC Unity",
  "Pure Storage Purity",
  "HPE Nimble",
  "TrueNAS",
 
  # Infrastructure Devices
  "APC PowerNet",
  "Raritan Dominion",
  "Eaton IPM",
  "Vertiv Avocent",
 
  # Voice/UC
  "Cisco Call Manager",
  "Avaya Aura",
 
  # Backup/Recovery
  "Veeam",
  "Commvault",
  "Rubrik",
 
  # Catch-all
  "Generic/SNMP",
  "Other"
]
}
 
variable "racks_map" {
  description = "Map of racks linked to sites and locations."
  type = map(object({
    name     = string
    site     = string   # Key from infrastructure_map
    location = string   # Name from the site's locations list
    status   = string   # e.g., "active", "reserved", "planned"
    u_height  = optional(number, 42) # Total rack height in U; default 42
    width    = optional(string, "19") # Rack width in inches (e.g. "19in", "23in"); default 19
  }))
  default = {}
}
 
variable "devices_map" {
  description = "Map of devices and their configurations."
  type = map(object({
    name           = string
    rack           = string       # Key from racks_map
    role           = string       # Must match a value in device_roles
    platform       = string       # Must match a value in platforms
    device_type    = string       # The Model name in NetBox
    has_vc         = bool         # True if part of a Virtual Chassis
    vdcs           = list(string)
    module_bay_id  = optional(number)
    module_type_id = optional(number)
    rack_position       = optional(number) # Lowest rack unit (U) the device occupies; null = unpositioned
    rack_face           = optional(string) # "front" or "rear"; required when position is set
  }))
  default = {}
}
 
variable "device_interfaces_map" {
  description = "Map of physical device interfaces to be created in NetBox."
  type = map(object({
    device   = string           # Key from devices_map
    name     = string           # Interface name as it appears on the device (e.g. "GigabitEthernet0/0")
    type     = string           # NetBox interface type slug (e.g. "1000base-t", "10gbase-x-sfpp")
    mode     = optional(string) # "access", "tagged", or "tagged-all"
    vlan_key = optional(string) # Key from vlans map (for access mode untagged VLAN)
    enabled  = optional(bool, true)
  }))
  default = {}
}
 
variable "vm_interfaces_map" {
  description = "Map of virtual machine interfaces to be created in NetBox."
  type = map(object({
    virtual_machine = string          # Key from virtual_machines_map
    name            = string
    enabled         = optional(bool, true)
  }))
  default = {}
}
 
#### VIRTUALIZATION ####
 
variable "cluster_types" {
  description = "List of cluster types to be created in NetBox (e.g. the hypervisor platform)."
  type        = list(string)
  default     = [
    "VMware vSphere",
    "Proxmox VE",
    "Microsoft Hyper-V",
    "Nutanix AOS",
    "KVM/QEMU",
    "Citrix Hypervisor",
    "OpenStack",
    "Other"
  ]
}
 
variable "clusters_map" {
  description = "Map of virtualization clusters to be created in NetBox."
  type = map(object({
    name         = string
    type         = string           # Must match a value in cluster_types
    site         = string           # Key from infrastructure_map
    description  = optional(string)
  }))
  default = {}
}
 
variable "virtual_machines_map" {
  description = "Map of virtual machines to be created in NetBox."
  type = map(object({
    name        = string
    cluster     = string            # Key from clusters_map
    status      = optional(string, "active")  # "active", "offline", "staged", "failed", "decommissioning"
    role        = optional(string)  # Must match a value in device_roles if provided
    platform    = optional(string)  # Must match a value in platforms if provided
    vcpus       = optional(number)
    memory_mb   = optional(number)
    disk_mb     = optional(number)
    description = optional(string)
  }))
  default = {}
}
 
variable "ip_addresses_map" {
  description = "Map of IP addresses to assign to device or VM interfaces."
  type = map(object({
    address        = string           # CIDR notation, e.g. "10.10.10.1/24"
    interface_key  = string           # Key from device_interfaces_map or vm_interfaces_map
    interface_type = string           # "device" or "vm"
    status         = optional(string, "active")
    dns_name       = optional(string)
    description    = optional(string)
    primary_ip4    = optional(bool, false) # Set as primary IPv4 on the parent device
  }))
  default = {}
}
 
 
#### IPAM ####
 
variable "rirs" {
  description = "Map of RIRs to be created in NetBox."
  type        = map(object({
    name = string
  }))
  default = {
    "ARIN"    = { name = "ARIN" },
    "RIPE"    = { name = "RIPE" },
    "APNIC"   = { name = "APNIC" },
    "LACNIC"  = { name = "LACNIC" },
    "AFRINIC" = { name = "AFRINIC" },
    "RFC1918" = { name = "RFC1918" },
  }
}
 
variable "aggregates" {
  description = "Map of aggregates to be created in NetBox."
  type        = map(object({
    prefix = string
    rir    = string
  }))
  default = {
    "internal_class_a" = { prefix = "10.0.0.0/8",     rir = "RFC1918" }
    "internal_class_b" = { prefix = "172.16.0.0/12",  rir = "RFC1918" }
    "internal_class_c" = { prefix = "192.168.0.0/16", rir = "RFC1918" }
  }
}
 
variable "vlans" {
  description = "Map of VLANs and their associated network prefixes."
  type = map(object({
    name        = string
    vid         = number
    site        = string
    prefix      = string
    description = string
    status       = optional(string, "active")
  }))
  default = {
    # "nyc_vlan10" = { name = "VLAN 10", vid = 10, site = "nyc_hq", prefix = "10.10.10.0/24", description = "NYC Management" },
    # "nyc_vlan20" = { name = "VLAN 20", vid = 20, site = "nyc_hq", prefix = "10.10.20.0/24", description = "NYC Servers" },
    # "nyc_vlan30" = { name = "VLAN 30", vid = 30, site = "nyc_hq", prefix = "10.10.30.0/24", description = "NYC Workstations", status = "reserved" },
  }
}