#--------------------------------------------------------------
# Virtual Machine Power Management
#--------------------------------------------------------------

# This action ensures only a single power action is performed if any of the VM extensions are updated

resource "terraform_data" "extension_trigger" {
  triggers_replace = [
    azurerm_virtual_machine_extension.aad_extension_windows[0],
    azurerm_virtual_machine_extension.aad_extension_linux[0],
    azurerm_virtual_machine_extension.extension[0],
    azurerm_virtual_machine_extension.custom_script_extension[0],
    azurerm_virtual_machine_extension.avd_register_session_host[0],
  ]

  lifecycle {
    action_trigger {
      events  = [before_create]
      actions = [action.azurerm_virtual_machine_power.power_action[0]]
    }
  }
}

# Can be updated via user input or automatically when a change to a VM extension occurs
action "azurerm_virtual_machine_power" "power_action" {
  count = var.vm_power_action != null ? 1 : 0

  config {
    virtual_machine_id = var.os_flavor == "windows" ? azurerm_windows_virtual_machine.win_vm[0].id : azurerm_linux_virtual_machine.linux_vm[0].id
    power_action       = var.vm_power_action
  }
}
