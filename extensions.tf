#--------------------------------------------------------------
# Enable AAD Login for Windows
#--------------------------------------------------------------
locals {
  mdm_settings = local.image["offer"] == "Windows-11" || local.image["offer"] == "Windows-10" ? jsonencode({ "mdmId" = "0000000a-0000-0000-c000-000000000000" }) : null
}
resource "azurerm_virtual_machine_extension" "aad_extension_windows" {
  count                      = var.os_flavor == "windows" && var.enable_aad_login == true ? 1 : 0
  name                       = "AADLoginForWindows"
  publisher                  = "Microsoft.Azure.ActiveDirectory"
  type                       = "AADLoginForWindows"
  type_handler_version       = "2.0"
  auto_upgrade_minor_version = true
  virtual_machine_id         = azurerm_windows_virtual_machine.win_vm[0].id

  settings = local.mdm_settings

}


#--------------------------------------------------------------
# Enable AAD Login for Linux
#--------------------------------------------------------------
resource "azurerm_virtual_machine_extension" "aad_extension_linux" {
  count                      = var.os_flavor == "linux" && var.enable_aad_login == true ? 1 : 0
  name                       = "AADSSHLogin"
  publisher                  = "Microsoft.Azure.ActiveDirectory"
  type                       = "AADSSHLoginForLinux"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true
  virtual_machine_id         = azurerm_linux_virtual_machine.linux_vm[0].id

}

#--------------------------------------------------------------
# Azure Virtual Machine Extensions
#--------------------------------------------------------------
resource "azurerm_virtual_machine_extension" "extension" {
  count = var.vm_extension == null ? 0 : 1

  name                        = var.vm_extension.name
  publisher                   = var.vm_extension.publisher
  type                        = var.vm_extension.type
  type_handler_version        = var.vm_extension.type_handler_version
  virtual_machine_id          = var.os_flavor == "windows" ? azurerm_windows_virtual_machine.win_vm[count.index].id : azurerm_linux_virtual_machine.linux_vm[count.index].id
  auto_upgrade_minor_version  = var.vm_extension.auto_upgrade_minor_version
  automatic_upgrade_enabled   = var.vm_extension.automatic_upgrade_enabled
  failure_suppression_enabled = var.vm_extension.failure_suppression_enabled
  protected_settings          = var.vm_extension.protected_settings
  settings                    = var.vm_extension.settings

  dynamic "protected_settings_from_key_vault" {
    for_each = var.vm_extension.protected_settings_from_key_vault == null ? [] : ["protected_settings_from_key_vault"]

    content {
      secret_url      = var.vm_extension.protected_settings_from_key_vault.secret_url
      source_vault_id = var.vm_extension.protected_settings_from_key_vault.source_vault_id
    }
  }

}

#--------------------------------------------------------------
# Azure Virtual Machine Disk Encryption
#--------------------------------------------------------------
resource "azurerm_virtual_machine_extension" "disk_encryption_windows" {
  count                      = lower(var.os_flavor) == "windows" && var.enable_disk_encryption == true ? 1 : 0
  name                       = "AzureDiskEncryption"
  virtual_machine_id         = var.os_flavor == "windows" ? azurerm_windows_virtual_machine.win_vm[count.index].id : azurerm_linux_virtual_machine.linux_vm[count.index].id
  publisher                  = "Microsoft.Azure.Security"
  type                       = "AzureDiskEncryption"
  type_handler_version       = var.type_handler_version != null ? var.type_handler_version : "2.2"
  auto_upgrade_minor_version = true

  settings = jsonencode({
    "EncryptionOperation" : var.encrypt_operation,
    "KeyVaultURL" : var.encryption_key_vault_uri,
    "KeyVaultResourceId" : var.encryption_key_vault_id,
    "KeyEncryptionKeyURL" : var.encryption_key_url,
    "KekVaultResourceId" : var.encryption_key_vault_id,
    "KeyEncryptionAlgorithm" : var.encryption_algorithm,
    "VolumeType" : var.volume_type
  })


  tags = var.tags
}

resource "azurerm_virtual_machine_extension" "disk_encryption_linux" {
  count                      = lower(var.os_flavor) == "linux" && var.enable_disk_encryption == true ? 1 : 0
  name                       = "AzureDiskEncryption"
  virtual_machine_id         = var.os_flavor == "windows" ? azurerm_windows_virtual_machine.win_vm[count.index].id : azurerm_linux_virtual_machine.linux_vm[count.index].id
  publisher                  = "Microsoft.Azure.Security"
  type                       = "AzureDiskEncryptionForLinux"
  type_handler_version       = var.type_handler_version != null ? var.type_handler_version : "1.1"
  auto_upgrade_minor_version = true

  settings = jsonencode({
    "EncryptionOperation" : var.encrypt_operation,
    "KeyVaultURL" : var.encryption_key_vault_uri,
    "KeyVaultResourceId" : var.encryption_key_vault_id,
    "KeyEncryptionKeyURL" : var.encryption_key_url,
    "KekVaultResourceId" : var.encryption_key_vault_id,
    "KeyEncryptionAlgorithm" : var.encryption_algorithm,
    "VolumeType" : var.volume_type
  })


  tags = var.tags
}

#--------------------------------------------------------------
# Extension CustomScriptExtension
#--------------------------------------------------------------
resource "azurerm_virtual_machine_extension" "custom_script_extension" {
  count                = var.custom_script_extension == null ? 0 : 1
  name                 = var.os_flavor == "windows" ? "CustomScriptExtension" : "CustomScript"
  publisher            = var.os_flavor == "windows" ? "Microsoft.Compute" : "Microsoft.Azure.Extensions"
  type                 = var.os_flavor == "windows" ? "CustomScriptExtension" : "CustomScript"
  type_handler_version = var.os_flavor == "windows" ? "1.10" : "2.1"
  virtual_machine_id   = var.os_flavor == "windows" ? azurerm_windows_virtual_machine.win_vm[count.index].id : azurerm_linux_virtual_machine.linux_vm[count.index].id

  settings = jsonencode({
    "timestamp" : var.custom_script_extension["rerun_script_extension"]
  })
  protected_settings = jsonencode({
    "commandToExecute" : var.custom_script_extension["command_to_execute"],
    "fileUris" : var.custom_script_extension["script_urls"],
    "managedIdentity" : {}
  })
  depends_on = [azurerm_role_assignment.role]

}

#--------------------------------------------------------------
# Extension AVD register session host
#--------------------------------------------------------------
resource "azurerm_virtual_machine_extension" "avd_register_session_host" {
  count                = var.avd_register_session_host == null ? 0 : 1
  name                 = "register-session-host-vmext"
  virtual_machine_id   = azurerm_windows_virtual_machine.win_vm[count.index].id
  publisher            = "Microsoft.Powershell"
  type                 = "DSC"
  type_handler_version = "2.83"

  settings = jsonencode({
    "modulesUrl" : var.avd_register_session_host["module_url"],
    "configurationFunction" : "Configuration.ps1\\AddSessionHost",
    "properties" : {
      "hostPoolName" : var.avd_register_session_host["host_pool_name"],
      "aadJoinPreview" : var.avd_register_session_host["aad_join"],
    }
  })
  protected_settings = jsonencode({
    "properties" : {
      "registrationInfoToken" : var.avd_register_session_host["registration_info_token"]
    }
  })

  lifecycle {
    ignore_changes = [type_handler_version, settings, protected_settings, tags]
    action_trigger {
      events  = [before_create, before_update]
      actions = [action.azurerm_virtual_machine_power.power_action[0]]
    }
  }
  depends_on = [azurerm_virtual_machine_extension.aad_extension_windows]
}
