# NetBox Terraform Module

A complete, production-ready Terraform module for managing NetBox infrastructure with proper DCIM, Virtualization, and IPAM resource provisioning.

## 📁 Module Structure

```
netbox-terraform/
├── provider.tf                 # Provider and Terraform configuration
├── variables.tf                # All input variable definitions
├── data.tf                     # Data sources for dynamic lookups
├── dcim.tf                     # DCIM resources (sites, devices, racks, interfaces)
├── ipam.tf                     # IPAM resources (VLANs, prefixes, VRFs, IP addresses)
├── virtualization.tf           # Virtualization resources (clusters, VMs, VM interfaces)
├── outputs.tf                  # Output values for all resources
├── terraform.tfvars.example    # Example configuration file
├── validate.sh                 # Pre-deployment validation script
└── README.md                   # This file
```

## 🎯 What This Module Does

This Terraform module provisions and manages NetBox infrastructure including:

### DCIM (Data Center Infrastructure Management)
- **Organizational Structure**: Regions, Tenant Groups, Tenants
- **Physical Infrastructure**: Sites, Locations, Racks
- **Device Management**: Platforms, Device Roles, Devices with rack positioning
- **Device Interfaces**: Physical interfaces with VLAN assignment and mode configuration
- **Advanced Features**: Virtual Chassis, Modules, Virtual Device Contexts (VDCs)
- **Primary IP Assignment**: Sets primary IPv4 addresses on physical devices

### Virtualization
- **Cluster Types**: Hypervisor platform definitions (vSphere, Proxmox, Hyper-V, etc.)
- **Clusters**: Physical groupings of hypervisor hosts scoped to sites
- **Virtual Machines**: VMs assigned to clusters with optional role, platform, and sizing
- **VM Interfaces**: Virtual network interfaces attached to VMs
- **Primary IP Assignment**: Sets primary IPv4 addresses on virtual machines

### IPAM (IP Address Management)
- **Registry**: Regional Internet Registries (RIRs)
- **Aggregates**: IP address space allocations
- **VRFs**: Virtual Routing and Forwarding instances per tenant
- **VLANs & Prefixes**: Network segmentation with automatic linking
- **IP Addresses**: Address assignment to both physical device interfaces and VM interfaces

## ✨ Key Features

- ✅ **Bug-Free**: All syntax and logic errors corrected
- ✅ **Dynamic Lookups**: Uses data sources instead of hardcoded IDs
- ✅ **Proper Relationships**: VLANs properly linked to prefixes; IPs linked to interfaces
- ✅ **Comprehensive Outputs**: All resource IDs exported for reference
- ✅ **Validation Tools**: Pre-deployment checks included
- ✅ **Full Documentation**: Complete guides and examples
- ✅ **Production Ready**: Best practices implemented
- ✅ **Virtualization Support**: Full cluster and VM lifecycle management
- ✅ **Interface Management**: Physical device and VM interfaces with IP assignment
- ✅ **Rack Positioning**: Devices placed at specific rack units for diagram rendering

## 🚀 Quick Start

### Prerequisites

1. **NetBox Instance**
   - Version compatible with provider 4.1.x
   - API access enabled
   - Valid API token with appropriate permissions

2. **Required Software**
   - Terraform >= 1.5.0
   - bash (for validation script)
   - curl (for connectivity checks)

3. **NetBox Setup**
   - Device types must exist before deployment
   - Manufacturers should be pre-configured

### Installation

```bash
# Clone or download the module files
cd netbox-terraform

# Copy and customize the example configuration
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars

# Update these required variables:
# - netbox_url: Your NetBox instance URL
# - netbox_token: Your API token
# - netbox_insecure: Set to true if using a self-signed certificate
# - infrastructure_map: Your site hierarchy
# - racks_map: Your rack definitions
# - devices_map: Your device inventory
# - vlans: Your VLAN definitions
```

### Deployment

```bash
# 1. Validate configuration (recommended)
./validate.sh

# 2. Initialize Terraform
terraform init

# 3. Review planned changes
terraform plan

# 4. Apply configuration
terraform apply

# 5. View created resources
terraform output infrastructure_summary
```

## 📋 Configuration Guide

### File: provider.tf
Configures the NetBox provider and Terraform version requirements.

**No changes needed** — uses variables from terraform.tfvars.

The provider now supports the `allow_insecure_https` flag, controlled by `var.netbox_insecure`. Set this to `true` when connecting to NetBox instances with self-signed TLS certificates.

### File: variables.tf
Defines all input variables with defaults and descriptions.

**Key Variables:**
- `netbox_url` — NetBox instance URL (required)
- `netbox_token` — API authentication token (required, sensitive)
- `netbox_insecure` — Skip TLS verification for self-signed certs (default: `false`)
- `infrastructure_map` — Site hierarchy and locations
- `device_roles` — Device role types (has defaults)
- `platforms` — Platform/OS types (has defaults)
- `racks_map` — Physical rack definitions (includes optional `u_height` and `width` fields, defaulting to 42U and 19")
- `devices_map` — Device inventory with optional rack positioning
- `device_interfaces_map` — Physical interfaces on devices
- `vm_interfaces_map` — Interfaces on virtual machines
- `ip_addresses_map` — IP addresses assigned to device or VM interfaces
- `cluster_types` — Hypervisor platform types (has defaults)
- `clusters_map` — Virtualization cluster definitions
- `virtual_machines_map` — Virtual machine inventory
- `rirs` — Regional Internet Registries (has defaults)
- `aggregates` — IP address aggregates (has defaults)
- `vlans` — VLAN and network prefix definitions

### File: data.tf
Data sources for looking up existing NetBox resources.

**Purpose:** Dynamically resolves device type IDs by model name instead of using hardcoded values.

**Current Data Sources:**
- `netbox_device_type` — Looks up device types for each unique model in `devices_map`

### File: dcim.tf
Creates all DCIM resources.

**Resource Creation Order:**
1. Platforms and Device Roles
2. Regions and Tenant Groups
3. Tenants
4. Sites
5. Locations
6. Racks
7. Virtual Chassis (for stacked devices)
8. Devices (with optional rack unit position)
9. Modules (for modular devices)
10. Virtual Device Contexts (VDCs) — commented, available for use
11. Device Interfaces (with optional VLAN assignment)
12. Device Primary IP assignment

**Key Features:**
- Flattens nested location structures
- Generates consistent device role colors via MD5
- Supports virtual chassis for stacked switches
- Handles modular devices with module bays
- Sets rack dimensions (`u_height`, `width`) from `racks_map`; prevents drift on every plan
- Places devices at specific rack units (`rack_position`, `rack_face`) for rack diagram rendering
- Assigns `location_id` on each device, derived from its rack's site and location — no extra tfvars wiring required
- Creates physical interfaces and assigns untagged VLANs in access mode
- Sets primary IPv4 on devices via `netbox_device_primary_ip`

### File: virtualization.tf
Creates all Virtualization resources. This is a new file added to the module.

**Resource Creation Order:**
1. Cluster Types (hypervisor platform definitions)
2. Clusters (scoped to sites from `infrastructure_map`)
3. Virtual Machines (assigned to clusters, with optional role, platform, and sizing)
4. VM Interfaces
5. VM Primary IP assignment

**Key Features:**
- Reuses existing `netbox_device_role` and `netbox_platform` resources from `dcim.tf` — no duplication
- VMs support optional vCPU, memory (MB), and disk (MB) sizing
- VM interfaces can receive IP addresses via `ip_addresses_map`
- Primary IPv4 assignment uses `netbox_primary_ip` linked to a VM interface

### File: ipam.tf
Creates all IPAM resources.

**Resource Creation Order:**
1. RIRs (Regional Internet Registries)
2. Aggregates (IP space allocations)
3. VRFs (one per unique tenant)
4. VLANs
5. Prefixes (automatically linked to VLANs)
6. IP Addresses for device interfaces (`interface_type = "device"`)
7. IP Addresses for VM interfaces (`interface_type = "vm"`)

**Key Features:**
- VLANs automatically linked to prefixes via `vlan_id`
- VLAN `status` is read from `each.value.status` — values like `"reserved"` or `"deprecated"` are applied correctly
- Prefixes properly scoped to sites
- VRFs created per tenant
- Optional VRF assignment for prefixes (commented, ready to enable)
- IP addresses handled in two separate resources based on `interface_type` to use the correct `object_type` (`dcim.interface` vs `virtualization.vminterface`)

### File: outputs.tf
Exports resource IDs and provides an infrastructure summary.

**Output Categories:**
- **DCIM Outputs**: IDs for regions, tenant groups, tenants, sites, locations, racks, device roles, platforms, devices, virtual chassis, device interfaces, device primary IPs
- **Virtualization Outputs**: IDs for cluster types, clusters, virtual machines, VM interfaces, VM primary IPs
- **IPAM Outputs**: IDs for RIRs, aggregates, VRFs, VLANs, prefixes, device IPs, VM IPs, and a merged `all_ip_ids` map
- **Summary Output**: Count of all created resources

**Usage:**
```bash
# View all outputs
terraform output

# Get specific output
terraform output site_ids

# Export as JSON
terraform output -json > infrastructure.json
```

## 📝 Configuration Examples

### Example 1: Basic Site Setup

```hcl
# terraform.tfvars

netbox_url      = "https://netbox.company.com"
netbox_token    = "your-secret-token-here"
netbox_insecure = false

infrastructure_map = {
  "hq" = {
    region       = "North America"
    tenant_group = "Corporate"
    tenant_name  = "IT Department"
    site_name    = "HQ-01"
    status       = "active"
    locations    = ["Server Room", "IDF-Floor-2"]
  }
}

racks_map = {
  "hq_r01" = {
    name     = "R01"
    site     = "hq"
    location = "Server Room"
    status   = "active"
    u_height = 42   # optional, default 42
    width    = 19   # optional, default 19
  }
}

devices_map = {
  "fw01" = {
    name          = "HQ-FW-01"
    rack          = "hq_r01"
    role          = "Firewall"
    platform      = "Palo Alto PAN-OS"
    device_type   = "PA-220"  # Must exist in NetBox
    has_vc        = false
    vdcs          = []
    rack_position = 1
    rack_face     = "front"
  }
}

vlans = {
  "hq_vlan10_mgmt" = {
    name        = "Management"
    vid         = 10
    site        = "hq"
    prefix      = "192.168.10.0/24"
    description = "Management Network"
  }
}
```

### Example 2: Multi-Site with Virtual Chassis

```hcl
infrastructure_map = {
  "dc1" = {
    region       = "North America"
    tenant_group = "Operations"
    tenant_name  = "Network Team"
    site_name    = "DC1-NYC"
    status       = "active"
    locations    = ["Row A", "Row B"]
  },
  "dc2" = {
    region       = "Europe"
    tenant_group = "Operations"
    tenant_name  = "Network Team"
    site_name    = "DC2-LON"
    status       = "active"
    locations    = ["Server Room"]
  }
}

devices_map = {
  # Virtual Chassis pair in DC1
  "dc1_sw01" = {
    name          = "DC1-CORE-01"
    rack          = "dc1_r01"
    role          = "Core Switch"
    platform      = "Cisco NX-OS"
    device_type   = "Nexus 9300"
    has_vc        = true
    vdcs          = []
    rack_position = 10
    rack_face     = "front"
  },
  "dc1_sw02" = {
    name          = "DC1-CORE-02"
    rack          = "dc1_r02"
    role          = "Core Switch"
    platform      = "Cisco NX-OS"
    device_type   = "Nexus 9300"
    has_vc        = true
    vdcs          = []
    rack_position = 10
    rack_face     = "front"
  }
}
```

### Example 3: Device Interfaces with IP Assignment

```hcl
device_interfaces_map = {
  "fw01_mgmt" = {
    device   = "fw01"
    name     = "Management"
    type     = "1000base-t"
    mode     = "access"
    vlan_key = "hq_vlan10_mgmt"
    enabled  = true
  },
  "fw01_wan" = {
    device   = "fw01"
    name     = "Ethernet1/1"
    type     = "10gbase-x-sfpp"
    enabled  = true
  }
}

ip_addresses_map = {
  "fw01_mgmt_ip" = {
    address        = "192.168.10.1/24"
    interface_key  = "fw01_mgmt"
    interface_type = "device"
    status         = "active"
    dns_name       = "fw01-mgmt.company.com"
    primary_ip4    = true
  }
}
```

### Example 4: Virtualization (Clusters and VMs)

```hcl
cluster_types = ["VMware vSphere", "Proxmox VE"]

clusters_map = {
  "dc1_vsphere" = {
    name        = "DC1-vSphere-Cluster"
    type        = "VMware vSphere"
    site        = "dc1"
    description = "Primary vSphere cluster"
  }
}

virtual_machines_map = {
  "web01" = {
    name        = "WEB-01"
    cluster     = "dc1_vsphere"
    status      = "active"
    role        = "Server"
    platform    = "Ubuntu Linux"
    vcpus       = 4
    memory_mb   = 8192
    disk_mb     = 51200
    description = "Web front-end"
  }
}

vm_interfaces_map = {
  "web01_eth0" = {
    virtual_machine = "web01"
    name            = "eth0"
    enabled         = true
  }
}

ip_addresses_map = {
  "web01_eth0_ip" = {
    address        = "10.10.20.10/24"
    interface_key  = "web01_eth0"
    interface_type = "vm"
    status         = "active"
    dns_name       = "web01.company.com"
    primary_ip4    = true
  }
}
```

## 🔑 Important Concepts

### TLS / Insecure HTTPS

When connecting to a NetBox instance with a self-signed certificate, set:

```hcl
netbox_insecure = true
```

This passes `allow_insecure_https = true` to the provider. Do not enable this in production without understanding the security implications.

### Site Keys vs Site Names

**Site Key** (`infrastructure_map` key): Used internally for Terraform references.  
**Site Name** (`site_name`): Display name in NetBox.

```hcl
# ✅ CORRECT
infrastructure_map = {
  "nyc_datacenter" = {  # ← This is the key
    site_name = "NYC-DC-01"  # ← This is the display name
  }
}

racks_map = {
  "rack1" = {
    site = "nyc_datacenter"  # ← Reference the KEY, not the site_name
  }
}
```

### VLAN Keys

VLAN keys must be unique strings. Do not use numeric VLAN IDs as map keys — HCL silently drops duplicate keys when the same ID appears across multiple sites:

```hcl
# ❌ WRONG — duplicate key "10" is silently dropped
vlans = {
  10 = { site = "dc1", ... }
  10 = { site = "dc2", ... }
}

# ✅ CORRECT — descriptive string keys are unique
vlans = {
  "dc1_vlan10_mgmt"  = { vid = 10, site = "dc1", ... }
  "dc2_vlan10_mgmt"  = { vid = 10, site = "dc2", ... }
}
```

### Location Matching

Locations in `racks_map` must **exactly match** entries in the site's location list:

```hcl
# ✅ CORRECT
infrastructure_map = {
  "hq" = {
    locations = ["Server Room A", "Floor 12 IDF"]
  }
}

racks_map = {
  "r01" = {
    site     = "hq"
    location = "Server Room A"  # ← Exact match
  }
}
```

### Device Types

Device types must exist in NetBox before deployment:

```hcl
devices_map = {
  "sw01" = {
    device_type = "Catalyst 9300-48P"  # ← Must match NetBox model exactly
  }
}
```

**Verify device types exist:**
```bash
curl -H "Authorization: Token YOUR_TOKEN" \
  "https://netbox.example.com/api/dcim/device-types/?model=Catalyst%209300-48P"
```

### Rack Dimensions

`racks_map` supports two optional fields that control the physical size of each rack in NetBox. Both default to standard values if omitted, so existing entries require no changes:

```hcl
racks_map = {
  "dc1_r01" = {
    name     = "R01"
    site     = "dc1"
    location = "Row A"
    status   = "active"
    u_height = 48   # override default of 42U
    width    = 19   # 19" or 23" — default 19"
  }
}
```

Without these fields in the resource block, Terraform treats them as null and will null them out on every plan even when NetBox already has values set — causing spurious in-place updates.

### Rack Positioning and Device Location

Setting `rack_position` and `rack_face` places a device at a specific rack unit, enabling rack diagram rendering in NetBox. Both fields are optional — omit them to leave the device unpositioned:

```hcl
devices_map = {
  "sw01" = {
    rack_position = 21       # Lowest U the device occupies
    rack_face     = "front"  # "front" or "rear"
    ...
  }
}
```

`location_id` is automatically derived from the device's rack assignment — no separate field is needed in `devices_map`. The module resolves it using the `"${site}_${location}"` key already established by the rack:

```hcl
# The device inherits its location from its rack — no extra config required
devices_map = {
  "sw01" = {
    rack = "dc1_r01"  # ← location_id is resolved from this rack's site + location
    ...
  }
}
```

### Virtual Chassis

Set `has_vc = true` for devices that are part of a stacked/clustered configuration. A `netbox_virtual_chassis` resource is created for each flagged device and the device is set as the chassis master at position 1:

```hcl
devices_map = {
  "sw01" = { has_vc = true, ... },
  "sw02" = { has_vc = true, ... }
}
```

### Device Interface Types

The `type` field in `device_interfaces_map` must use NetBox interface type slugs:

| Slug | Description |
|---|---|
| `1000base-t` | 1GbE copper |
| `10gbase-x-sfpp` | 10GbE SFP+ |
| `25gbase-x-sfp28` | 25GbE SFP28 |
| `40gbase-x-qsfpp` | 40GbE QSFP+ |
| `100gbase-x-qsfp28` | 100GbE QSFP28 |
| `virtual` | Virtual/logical interface |

### IP Address Assignment

IP addresses are split into two resources based on `interface_type` to satisfy NetBox's `object_type` requirement:

- `interface_type = "device"` → uses `object_type = "dcim.interface"` and references `netbox_device_interface`
- `interface_type = "vm"` → uses `object_type = "virtualization.vminterface"` and references `netbox_interface`

Set `primary_ip4 = true` on an IP entry to promote it to the primary IPv4 address of the parent device or VM.

### Virtual Device Contexts (VDCs)

For devices that support multiple virtual contexts (like Cisco ASA or FortiGate), define them in `vdcs`. The `netbox_virtual_device_context` resource block is included in `dcim.tf` and can be uncommented to activate it:

```hcl
devices_map = {
  "fw01" = {
    vdcs = ["Admin", "Guest", "Internal"]
  }
}
```

## 🛠️ Advanced Usage

### Using Outputs for Downstream Resources

```hcl
data "terraform_remote_state" "netbox" {
  backend = "s3"
  config = {
    bucket = "terraform-state"
    key    = "netbox/terraform.tfstate"
  }
}

resource "some_resource" "example" {
  site_id = data.terraform_remote_state.netbox.outputs.site_ids["hq"]
}
```

### Conditional VRF Assignment

To assign prefixes to VRFs, uncomment in `ipam.tf`:

```hcl
resource "netbox_prefix" "prefixes" {
  # ... other attributes ...
  vrf_id = netbox_vrf.vrfs[var.infrastructure_map[each.value.site].tenant_name].id
}
```

### Custom Device Roles and Platforms

Override defaults by defining them in `terraform.tfvars`:

```hcl
device_roles = [
  "Firewall",
  "Core Switch",
  "Access Switch"
]

platforms = [
  "Cisco IOS",
  "Arista EOS",
  "Juniper JUNOS"
]
```

### Custom Cluster Types

Override the default hypervisor platform list:

```hcl
cluster_types = [
  "VMware vSphere",
  "Proxmox VE"
]
```

## ✅ Validation

### Pre-Deployment Validation

Run the validation script before deployment:

```bash
./validate.sh
```

**Checks performed:**
- Terraform installation
- Syntax validation
- Required files present
- NetBox connectivity
- Configuration structure
- Plan validation

### Manual Validation Commands

```bash
# Validate Terraform syntax
terraform validate

# Check formatting
terraform fmt -check

# Detailed plan
terraform plan -out=tfplan
terraform show tfplan

# List planned changes
terraform show -json tfplan | jq '.resource_changes[].change.actions'
```

## 🔧 Troubleshooting

### Common Issues

#### Issue: "Device type not found"

**Cause:** Device type doesn't exist in NetBox.

**Solution:**
```bash
curl -H "Authorization: Token YOUR_TOKEN" \
  "https://netbox.example.com/api/dcim/device-types/" | jq '.results[].model'
```

#### Issue: "No configuration files"

**Cause:** Missing `terraform.tfvars`.

**Solution:**
```bash
cp terraform.tfvars.example terraform.tfvars
```

#### Issue: "Site key not found"

**Cause:** Rack, VLAN, or cluster references an incorrect site key.

**Solution:**
```hcl
infrastructure_map = { "dc1" = {...} }
racks_map          = { "r01" = { site = "dc1" } }   # Must match key
vlans              = { "vlan10" = { site = "dc1" } } # Must match key
clusters_map       = { "cl01"  = { site = "dc1" } }  # Must match key
```

#### Issue: "Location not found"

**Cause:** Location name doesn't match exactly (case-sensitive, spaces matter).

**Solution:**
```hcl
infrastructure_map = {
  "dc1" = { locations = ["Server Room A"] }
}
racks_map = {
  "r01" = { location = "Server Room A" }  # Exact match required
}
```

#### Issue: "TLS certificate error"

**Cause:** NetBox is using a self-signed certificate.

**Solution:**
```hcl
netbox_insecure = true
```

#### Issue: Duplicate VLAN IDs silently missing

**Cause:** Numeric map keys are deduplicated by HCL when the same VLAN ID appears for multiple sites.

**Solution:** Use descriptive string keys (e.g. `"dc1_vlan10_mgmt"`) instead of numeric keys.

### Debug Mode

```bash
export TF_LOG=DEBUG
terraform plan
```

### State Inspection

```bash
# List all resources
terraform state list

# Show specific resource
terraform state show 'netbox_device.devices["fw01"]'

# Check for drift
terraform plan -refresh-only
```

## 📚 Additional Documentation

- **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)** — One-page command reference
- **[CHANGELOG.md](CHANGELOG.md)** — Detailed change history
- **[MIGRATION.md](MIGRATION.md)** — Upgrade guide from original version
- **[SUMMARY.md](SUMMARY.md)** — Executive summary of corrections

## 🔐 Security Considerations

### Sensitive Variables

The `netbox_token` variable is marked as sensitive. Best practices:

```bash
# Option 1: Use environment variables
export TF_VAR_netbox_token="your-token-here"
terraform apply

# Option 2: Use a .tfvars file (not committed to Git)
echo 'netbox_token = "your-token-here"' > secrets.tfvars
terraform apply -var-file=secrets.tfvars

# Option 3: Use a secrets manager
# (AWS Secrets Manager, HashiCorp Vault, etc.)
```

### State File Protection

The state file contains sensitive information:

```bash
terraform {
  backend "s3" {
    bucket         = "terraform-state"
    key            = "netbox/terraform.tfstate"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
```

## 🤝 Contributing

To extend this module:

1. Follow existing naming conventions
2. Add outputs for new resources
3. Update documentation
4. Test thoroughly
5. Add examples

## 📝 Requirements

- Terraform >= 1.5.0
- NetBox provider e-breuninger/netbox ~> 4.1.0
- NetBox instance (compatible version)
- Valid API token with permissions:
  - `dcim.add_*` / `dcim.change_*`
  - `ipam.add_*` / `ipam.change_*`
  - `virtualization.add_*` / `virtualization.change_*`

## 📄 License

Copyright (c) 2026 [SMS Data Products](https://www.sms.com)

Licensed under the Apache License, Version 2.0. You may not use this file except in compliance with the License. You may obtain a copy at:

[http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

## 🆘 Support

1. Review documentation in this repository
2. Run `./validate.sh` for configuration validation
3. Check the [Troubleshooting](#-troubleshooting) section
4. Enable debug logging: `TF_LOG=DEBUG`
5. Review NetBox provider documentation

