# Azure Virtual Machines Terraform Module

[![Changelog](https://img.shields.io/badge/changelog-release-green.svg)](https://github.com/miljodir/terraform-azurerm-virtual-machine/wiki/main#changelog)
[![TF Registry](https://img.shields.io/badge/terraform-registry-blue.svg)](https://registry.terraform.io/modules/miljodir/virtual-machine/azurerm/)

This terraform module is designed to deploy azure Windows or Linux virtual machines with Public IP, Availability Set and Network Security Group support. This module also works for AVD (Azure Virtual Desktop) deployments.

These types of resources supported:

* [Linux Virtual Machine](https://www.terraform.io/docs/providers/azurerm/r/linux_virtual_machine.html)
* [Windows Virtual Machine](https://www.terraform.io/docs/providers/azurerm/r/windows_virtual_machine.html)
* [Linux VM with SQL Server](https://docs.microsoft.com/en-us/azure/azure-sql/virtual-machines/linux/sql-vm-create-portal-quickstart)
* [Windows VM with SQL Server](https://docs.microsoft.com/en-us/azure/azure-sql/virtual-machines/windows/sql-vm-create-portal-quickstart)
* [SSH2 Key generation for Dev Environments](https://www.terraform.io/docs/providers/tls/r/private_key.html)
* [Azure Monitoring Diagnostics](https://www.terraform.io/docs/providers/azurerm/r/monitor_diagnostic_setting.html)

## VM Power Management

This module now supports controlling the power state of VMs via the `vm_power_action` variable. This allows you to:

- Power on VMs that are stopped
- Power off running VMs
- Restart VMs

### Requirements

- Terraform >= 1.14 (for action support)
- AzureRM provider > 3.0, < 5.0

### Usage

To control the power state of a VM, set the `vm_power_action` variable:

```hcl
module "vm" {
  source = "miljodir/virtual-machine/azurerm"
  
  # ... other configuration ...
  
  # Power off the VM after all extensions are applied
  vm_power_action = "power_off"
}
```

**Supported values:**
- `null` (default): No power action is taken
- `"power_on"`: Powers on the VM if it's stopped
- `"power_off"`: Powers off the VM
- `"restart"`: Restarts the VM

### Extension Behavior

VM extensions are always applied while the VM is running (VMs are created in a running state by default). The power action, if specified, is executed **after** all extensions have been successfully applied. This ensures that:

1. Extensions with Create/Read/Delete (CRD) operations complete successfully
2. The VM can be powered off or restarted after configuration is complete
3. No extension failures occur due to the VM being in a stopped state

### Use Case: GitHub Actions

You can use this with GitHub Actions workflows by passing the power action as a Terraform variable:

```yaml
- name: Terraform Apply
  run: terraform apply -var="vm_power_action=power_off" -auto-approve
```

This allows you to control VM power states dynamically based on your CI/CD pipeline needs.

### Complete Example

```hcl
module "dev_vm" {
  source  = "miljodir/virtual-machine/azurerm"
  version = "~> 1.0"

  resource_group_name  = "my-resource-group"
  virtual_machine_name = "dev-vm-001"
  location             = "norwayeast"
  subnet_id            = azurerm_subnet.example.id
  
  os_flavor                   = "linux"
  linux_distribution_name     = "ubuntu2404"
  virtual_machine_size        = "Standard_B2as_v2"
  admin_username              = "adminuser"
  generate_admin_ssh_key      = true
  
  # Enable AAD login extension
  enable_aad_login = true
  
  # Power off the VM after deployment to save costs
  vm_power_action = "power_off"
  
  tags = {
    Environment = "Development"
    ManagedBy   = "Terraform"
  }
}
```

### Use Cases

1. **Cost Optimization**: Power off development/test VMs outside business hours:
   ```bash
   # Morning: Power on the VM
   terraform apply -var="vm_power_action=power_on"
   
   # Evening: Power off the VM
   terraform apply -var="vm_power_action=power_off"
   ```

2. **Maintenance**: Restart VMs after applying configuration changes:
   ```hcl
   vm_power_action = "restart"
   ```

3. **CI/CD Integration**: Dynamically control VM states based on pipeline variables:
   ```yaml
   jobs:
     deploy:
       steps:
         - name: Deploy with Power Action
           run: |
             terraform apply \
               -var="vm_power_action=${{ github.event.inputs.power_action }}" \
               -auto-approve
   ```
