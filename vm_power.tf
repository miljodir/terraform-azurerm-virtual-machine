#--------------------------------------------------------------
# Virtual Machine Power Management
#--------------------------------------------------------------

# User-controlled power action
# This action runs after all extensions are applied
action "azurerm_virtual_machine_power" "user_action" {
  count = var.vm_power_action != null ? 1 : 0

  config {
    virtual_machine_id = var.os_flavor == "windows" ? azurerm_windows_virtual_machine.win_vm[0].id : azurerm_linux_virtual_machine.linux_vm[0].id
    power_action       = var.vm_power_action
  }
}
