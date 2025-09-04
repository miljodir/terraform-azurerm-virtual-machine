#---------------------------------------------------------------
# Generates SSH2 key Pair for Linux VM's (Dev Environment only)
#---------------------------------------------------------------
resource "tls_private_key" "rsa" {
  count     = var.generate_admin_ssh_key == true && var.os_flavor == "linux" ? 1 : 0
  algorithm = "ED25519"
  rsa_bits  = 4096

  lifecycle {
    ignore_changes = [
      #rsa_bits,
      algorithm
    ]
  }
}

#----------------------------------------------------------
# Resource Group, VNet, Subnet selection & Random Resources
#----------------------------------------------------------
resource "random_password" "passwd" {
  count       = (var.disable_password_authentication != true && var.os_flavor == "linux") || (var.os_flavor == "windows" && var.admin_password == null) ? 1 : 0
  length      = 24
  min_upper   = 4
  min_lower   = 2
  min_numeric = 4
  special     = false

  keepers = {
    admin_password = var.os_flavor
  }
}

#---------------------------------------
# Network Interface for Virtual Machine
#---------------------------------------
resource "azurerm_network_interface" "nic" {
  name                           = var.nic_name != null ? var.nic_name : "${var.virtual_machine_name}-nic"
  resource_group_name            = var.resource_group_name
  location                       = var.location
  dns_servers                    = var.dns_servers
  ip_forwarding_enabled          = false
  accelerated_networking_enabled = var.enable_accelerated_networking
  tags                           = var.tags

  ip_configuration {
    name                          = var.ipconfig_name
    primary                       = true
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = var.private_ip_address_allocation_type
    private_ip_address            = var.private_ip_address_allocation_type == "Static" ? var.private_ip_address : null
  }
}

#---------------------------------------
# Managed disk creation and attachment
#---------------------------------------

resource "azurerm_managed_disk" "osdisk_create" {
  count                = var.osdisk == {} ? 0 : 1
  name                 = var.osdisk.override_name != null ? var.osdisk.override_name : "${var.virtual_machine_name}-osdisk"
  location             = var.location
  resource_group_name  = var.resource_group_name
  storage_account_type = "StandardSSD_LRS"
  create_option        = var.osdisk.create_option
  disk_size_gb         = var.osdisk.size
  os_type              = var.os_flavor == "windows" ? "Windows" : "Linux"

  lifecycle {
    ignore_changes = [
      source_resource_id,
      hyper_v_generation,
      disk_iops_read_only,
      disk_iops_read_write,
      disk_mbps_read_only,
      disk_mbps_read_write,
      on_demand_bursting_enabled,
      trusted_launch_enabled,
      upload_size_bytes,
      tags,

    ]
  }
}

resource "azurerm_managed_disk" "datadisks_create" {
  for_each             = var.datadisks
  name                 = each.value.override_name != null ? each.value.override_name : "${var.virtual_machine_name}-datadisk${each.value.lun}"
  location             = var.location
  resource_group_name  = var.resource_group_name
  storage_account_type = each.value.type
  create_option        = "Empty"
  disk_size_gb         = each.value.size
  zone                 = var.availability_zone

  lifecycle {
    ignore_changes = [
      encryption_settings,
      zone
    ]
  }
}

resource "azurerm_virtual_machine_data_disk_attachment" "datadisks_attach" {
  for_each           = var.datadisks
  managed_disk_id    = azurerm_managed_disk.datadisks_create[each.key].id
  virtual_machine_id = var.os_flavor == "windows" ? azurerm_windows_virtual_machine.win_vm[0].id : azurerm_linux_virtual_machine.linux_vm[0].id
  lun                = each.value.lun
  caching            = each.value.caching
}

#---------------------------------------
# Linux Virtual machine
#---------------------------------------
resource "azurerm_linux_virtual_machine" "linux_vm" {
  count                                                  = var.os_flavor == "linux" ? 1 : 0
  name                                                   = var.virtual_machine_name
  computer_name                                          = var.host_name
  resource_group_name                                    = var.resource_group_name
  location                                               = var.location
  size                                                   = var.virtual_machine_size
  admin_username                                         = azurerm_managed_disk.osdisk_create[0].id == null ? var.admin_username : null
  admin_password                                         = var.disable_password_authentication != true && var.admin_password == null ? try(random_password.passwd[0].result, null) : var.admin_password
  network_interface_ids                                  = [azurerm_network_interface.nic.id]
  source_image_id                                        = var.source_image_id != null ? var.source_image_id : null
  provision_vm_agent                                     = azurerm_managed_disk.osdisk_create[0].id == null ? var.provision_vm_agent : null
  allow_extension_operations                             = var.allow_extension_operations
  encryption_at_host_enabled                             = var.encryption_at_host_enabled
  dedicated_host_id                                      = var.dedicated_host_id
  availability_set_id                                    = var.availability_set_id
  zone                                                   = var.availability_zone
  tags                                                   = var.tags
  patch_mode                                             = azurerm_managed_disk.osdisk_create[0].id == null ? var.patch_mode : null
  patch_assessment_mode                                  = azurerm_managed_disk.osdisk_create[0].id == null ? var.patch_assessment_mode : null
  bypass_platform_safety_checks_on_user_schedule_enabled = azurerm_managed_disk.osdisk_create[0].id == null ? var.bypass_platform_safety_checks_on_user_schedule_enabled : null
  secure_boot_enabled                                    = var.secure_boot_enabled
  vtpm_enabled                                           = var.vtpm_enabled
  disk_controller_type                                   = var.disk_controller_type
  os_managed_disk_id                                     = azurerm_managed_disk.osdisk_create[0].id != null ? azurerm_managed_disk.osdisk_create[0].id : null

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.generate_admin_ssh_key == true && var.os_flavor == "linux" ? tls_private_key.rsa[0].public_key_openssh : file(var.admin_ssh_key_data)
  }

  dynamic "source_image_reference" {
    for_each = azurerm_managed_disk.osdisk_create[0].id != null ? [] : [1]
    content {
      publisher = local.image["publisher"]
      offer     = local.image["offer"]
      sku       = local.image["sku"]
      version   = local.image["version"]
    }
  }

  os_disk {
    storage_account_type = var.os_disk_storage_account_type
    caching              = "ReadWrite"
    name                 = var.os_disk_name != null ? var.os_disk_name : "${var.virtual_machine_name}-osdisk"
    disk_size_gb         = var.os_disk_size_gb != null ? var.os_disk_size_gb : null
  }

  dynamic "additional_capabilities" {
    for_each = var.additional_capabilities == null ? [] : ["additional_capabilities"]

    content {
      ultra_ssd_enabled   = var.additional_capabilities.ultra_ssd_enabled
      hibernation_enabled = var.additional_capabilities.hibernation_enabled
    }
  }

  boot_diagnostics {}

  dynamic "identity" {
    for_each = var.enable_managed_identity == false ? [] : [1]
    content {
      type = "SystemAssigned"
    }
  }

  lifecycle {
    ignore_changes = [
      identity,
      source_image_reference[0],
      secure_boot_enabled, # Gen2 VMs only
      vtpm_enabled,        # Gen2 VMs only
    ]
  }
}

#---------------------------------------
# Windows Virtual machine
# Note that VM resource name and hostname is generated differently
# Because of windows hostname limitations, prefix is omitted
#---------------------------------------
# var.disable_password_authentication != true && var.admin_password == null ? try(random_password.passwd[0].result, null) : var.admin_password
resource "azurerm_windows_virtual_machine" "win_vm" {
  count                                                  = var.os_flavor == "windows" ? 1 : 0
  name                                                   = var.virtual_machine_name
  computer_name                                          = var.host_name
  resource_group_name                                    = var.resource_group_name
  location                                               = var.location
  size                                                   = var.virtual_machine_size
  admin_username                                         = azurerm_managed_disk.osdisk_create[0].id == null ? var.admin_username : null
  admin_password                                         = var.admin_password == null ? random_password.passwd[0].result : var.admin_password
  network_interface_ids                                  = [azurerm_network_interface.nic.id]
  source_image_id                                        = var.source_image_id != null ? var.source_image_id : null
  provision_vm_agent                                     = azurerm_managed_disk.osdisk_create[0].id == null ? var.provision_vm_agent : null
  allow_extension_operations                             = var.allow_extension_operations
  encryption_at_host_enabled                             = var.encryption_at_host_enabled
  dedicated_host_id                                      = var.dedicated_host_id
  license_type                                           = var.license_type
  availability_set_id                                    = var.availability_set_id
  zone                                                   = var.availability_zone
  patch_mode                                             = azurerm_managed_disk.osdisk_create[0].id == null ? var.patch_mode : null
  patch_assessment_mode                                  = azurerm_managed_disk.osdisk_create[0].id == null ? var.patch_assessment_mode : null
  bypass_platform_safety_checks_on_user_schedule_enabled = azurerm_managed_disk.osdisk_create[0].id == null ? var.bypass_platform_safety_checks_on_user_schedule_enabled : null
  enable_automatic_updates                               = azurerm_managed_disk.osdisk_create[0].id == null ? var.enable_automatic_updates : null
  timezone                                               = var.timezone
  secure_boot_enabled                                    = var.secure_boot_enabled
  vtpm_enabled                                           = var.vtpm_enabled
  hotpatching_enabled                                    = azurerm_managed_disk.osdisk_create[0].id == null ? var.hotpatching_enabled : null
  tags                                                   = var.tags
  disk_controller_type                                   = var.disk_controller_type
  os_managed_disk_id                                     = azurerm_managed_disk.osdisk_create[0].id != null ? azurerm_managed_disk.osdisk_create[0].id : null

  dynamic "source_image_reference" {
    for_each = azurerm_managed_disk.osdisk_create[0].id != null ? [] : [1]
    content {
      publisher = local.image["publisher"]
      offer     = local.image["offer"]
      sku       = local.image["sku"]
      version   = local.image["version"]
    }
  }

  os_disk {
    storage_account_type = azurerm_managed_disk.osdisk_create[0].id != null ? var.os_disk_storage_account_type : null
    caching              = "ReadWrite"
    name                 = azurerm_managed_disk.osdisk_create[0].id != null ? null : var.os_disk_name != null ? var.os_disk_name : "${var.virtual_machine_name}-osdisk"
    disk_size_gb         = var.os_disk_size_gb
  }

  dynamic "additional_capabilities" {
    for_each = var.additional_capabilities == null ? [] : ["additional_capabilities"]

    content {
      ultra_ssd_enabled   = var.additional_capabilities.ultra_ssd_enabled
      hibernation_enabled = var.additional_capabilities.hibernation_enabled
    }
  }

  boot_diagnostics {}

  dynamic "identity" {
    for_each = var.enable_managed_identity == false ? [] : [1]
    content {
      type = "SystemAssigned"
    }
  }

  lifecycle {
    ignore_changes = [
      timezone,
      zone,
      identity,
      secure_boot_enabled, # Gen2 VMs only
      vtpm_enabled,        # Gen2 VMs only
    ]
  }
}

#--------------------------------------------------------------
# Update management center
#--------------------------------------------------------------
resource "azurerm_maintenance_assignment_virtual_machine" "main" {
  count                        = var.patch_mode == "AutomaticByPlatform" && var.maintenance_configuration_id != null ? 1 : 0
  location                     = var.location
  maintenance_configuration_id = var.maintenance_configuration_id
  virtual_machine_id           = var.os_flavor == "windows" ? azurerm_windows_virtual_machine.win_vm[0].id : azurerm_linux_virtual_machine.linux_vm[0].id
}

#--------------------------------------------------------------
# SystemAssigned identity roles
#--------------------------------------------------------------
resource "azurerm_role_assignment" "role" {
  for_each             = var.managed_identity_roles
  scope                = each.value.scope
  role_definition_name = each.value.role_definition_name
  principal_id         = var.os_flavor == "windows" ? azurerm_windows_virtual_machine.win_vm[0].identity[0].principal_id : azurerm_linux_virtual_machine.linux_vm[0].identity[0].principal_id
  principal_type       = "ServicePrincipal"
}
