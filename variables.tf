variable "resource_group_name" {
  type        = string
  description = "A container that holds related resources for an Azure solution"
}

variable "subnet_id" {
  type        = string
  description = "The ID of the subnet that the VM should use"
}

variable "location" {
  type        = string
  description = "The Azure Region in which all resources should be created"
  default     = "norwayeast"
}

variable "virtual_machine_name" {
  type        = string
  description = "The name of the virtual machine. Max 15 characters if os_flavor is set to `windows`"
}

variable "host_name" {
  type        = string
  description = "Override the hostname of the virtual machine."
  default     = null
}

variable "os_flavor" {
  type        = string
  description = "Specify the flavor of the operating system image to deploy Virtual Machine. Valid values are `windows` and `linux`"
  default     = "windows"
  validation {
    condition = (
      var.os_flavor == "windows" || var.os_flavor == "linux"
    )
    error_message = "Valid values are `windows` and `linux`"
  }
}

variable "virtual_machine_size" {
  type        = string
  description = "The Virtual Machine SKU for the Virtual Machine, Default is Standard_B2as_v2"
  default     = "Standard_B2as_v2"
}

variable "enable_accelerated_networking" {
  type        = bool
  description = "Should Accelerated Networking be enabled? Defaults to false."
  default     = false
}

variable "private_ip_address_allocation_type" {
  type        = string
  description = "The allocation method used for the Private IP Address. Possible values are Dynamic and Static."
  default     = "Dynamic"
  validation {
    condition = (
      var.private_ip_address_allocation_type == "Dynamic" || var.private_ip_address_allocation_type == "Static"
    )
    error_message = "Valid values are `Dynamic` and `Static`"
  }
}

variable "private_ip_address" {
  type        = string
  description = "The Static IP Address which should be used. This is valid only when `private_ip_address_allocation` is set to `Static` "
  default     = null
}

variable "dns_servers" {
  type        = list(string)
  description = "List of dns servers to use for network interface"
  default     = []
}

variable "availability_set_id" {
  type        = string
  description = "Attach the vm to a availability set. Only 'availability_zone' or 'availability_set_id' can be used"
  default     = null
}

variable "source_image_id" {
  type        = string
  description = "The ID of an Image which each Virtual Machine should be based on"
  default     = null
}

variable "custom_image" {
  description = "Provide the custom image to this module if the default variants are not sufficient"
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = optional(string, "latest")
  })
  default = null
}

variable "linux_distribution_name" {
  type        = string
  default     = "ubuntu2404"
  description = "Variable to pick an OS flavour for Linux based VM."
}

variable "windows_distribution_name" {
  type        = string
  default     = "windows2025az"
  description = "Variable to pick an OS flavour for Windows based VM."
}

variable "os_disk_storage_account_type" {
  type        = string
  description = "The Type of Storage Account which should back this the Internal OS Disk. Possible values include Standard_LRS, StandardSSD_LRS and Premium_LRS."
  default     = "Premium_LRS"
}

variable "os_disk_size_gb" {
  type        = number
  description = "Override the OS disk size the size used in the image this Virtual Machine is sourced from."
  default     = null
}

variable "os_disk_name" {
  type        = string
  default     = null
  description = "Override the OS disk name. If not set, the name will be generated from the virtual machine name."

}

variable "generate_admin_ssh_key" {
  type        = bool
  description = "Generates a secure private key and encodes it as PEM."
  default     = true
}

variable "admin_ssh_key_data" {
  type        = string
  description = "specify the path to the existing SSH key to authenticate Linux virtual machine"
  default     = null
}

variable "disable_password_authentication" {
  type        = bool
  description = "Should Password Authentication be disabled on this Virtual Machine? Defaults to true. Only valid for Linux Virtual Machines."
  default     = true
}

variable "admin_username" {
  type        = string
  description = "The username of the local administrator used for the Virtual Machine."
  default     = "sysadmin"
}

variable "admin_password" {
  type        = string
  description = "The Password which should be used for the local-administrator on this Virtual Machine"
  default     = null
  sensitive   = true
}

variable "dedicated_host_id" {
  type        = string
  description = "The ID of a Dedicated Host where this machine should be run on."
  default     = null
}

variable "license_type" {
  type        = string
  description = "Specifies the type of on-premise license which should be used for this Virtual Machine. Possible values are None, Windows_Client and Windows_Server."
  default     = "None"
  validation {
    condition     = var.license_type == "None" || var.license_type == "Windows_Client" || var.license_type == "Windows_Server"
    error_message = "license_type must be one of None, Windows_Client or Windows_Server"
  }
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = null
}

variable "enable_disk_encryption" {
  type        = bool
  description = "Set to true if disk encryption is not necessary."
  default     = false
}

variable "patch_mode" {
  type        = string
  description = "Possible values are Manual, AutomaticByOS, AutomaticByPlatform and ImageDefault"
  default     = "AutomaticByPlatform"
}

variable "patch_assessment_mode" {
  type        = string
  description = "Possible values are ImageDefault, AutomaticByPlatform"
  default     = "AutomaticByPlatform"
}

variable "hotpatching_enabled" {
  type        = bool
  description = "Enable or disable hotpatching for the VM. Defaults to false."
  default     = false
}

variable "bypass_platform_safety_checks_on_user_schedule_enabled" {
  type        = bool
  description = "Set to true if platform safety checks should be bypassed on user schedule. Defaults to false."
  default     = true
}

variable "enable_automatic_updates" {
  type        = bool
  description = "Enable automatic updates of windows VM? Defaults to true."
  default     = true
}

variable "vm_agent_platform_updates_enabled" {
  type        = bool
  description = "(DEPRECATED - remove in next major version bump) Enable or disable VM Agent platform updates. Defaults to true."
  default     = true
}

variable "timezone" {
  type        = string
  description = "Time zone for virtual machine. Defaults to 'W. Europe Standard Time'. https://jackstromberg.com/2017/01/list-of-time-zones-consumed-by-azure/"
  default     = "W. Europe Standard Time"
}

variable "enable_managed_identity" {
  type        = bool
  description = "Set to true if the machine should be equipped with a managed identity. Defaults to false."
  default     = false
}

variable "datadisks" {
  description = "The disks to create and attach"
  default     = {}

  type = map(object({
    size          = string
    type          = string
    caching       = string
    lun           = number
    override_name = optional(string, null)
  }))
}

variable "enable_aad_login" {
  type        = bool
  description = "Set to true if you want to enable AAD Login VM extension"
  default     = false
}

variable "availability_zone" {
  type        = number
  description = "Set to a zone if you want the vm placed in a specific availability zone. One module instance supports only a single zone."
  default     = null
}

variable "encryption_key_vault_uri" {
  type        = string
  description = "Key vault uri if encrypting disks. Must be in same subscription."
  default     = null
}

variable "encryption_key_vault_id" {
  type        = string
  description = "Key vault id if encrypting disks. Remember to allow for disk encryption usage."
  default     = null
}

variable "encryption_at_host_enabled" {
  type        = bool
  description = "Enable or disable encryption at host. Cannot be used with Azure Disk Encryption. Defaults to false."
  default     = true
}

variable "vm_extension" {
  description = "Argument to create `azurerm_virtual_machine_extension` resource, the argument descriptions could be found at [the document](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_extension)."
  type = object({
    name                        = string
    publisher                   = string
    type                        = string
    type_handler_version        = string
    auto_upgrade_minor_version  = optional(bool)
    automatic_upgrade_enabled   = optional(bool)
    failure_suppression_enabled = optional(bool, false)
    settings                    = optional(string)
    protected_settings          = optional(string)
    protected_settings_from_key_vault = optional(object({
      secret_url      = string
      source_vault_id = string
    }))
  })
  default   = null
  sensitive = true # Because `protected_settings` is sensitive
}

variable "allow_extension_operations" {
  type        = bool
  description = "Enable or disable VM extension operations? Defaults to true."
  default     = true
}

variable "provision_vm_agent" {
  type        = bool
  description = "Enable or disable provision of VM agent? Defaults to true."
  default     = true
}

# Disk encryption variables
variable "encryption_key_url" {
  type        = string
  description = "URL to Key Encrypt Key (KEK)"
  default     = ""
}

variable "encryption_algorithm" {
  type        = string
  description = "Encryption Algorithm. Defaults to RSA-OAEP."
  default     = "RSA-OAEP"
}

variable "volume_type" {
  type        = string
  description = "Value for which disks to encrypt. Defaults to All."
  default     = "All"
}

variable "encrypt_operation" {
  type        = string
  description = "Value for which encrypt operation. Defaults to EnableEncryption."
  default     = "EnableEncryption"
}

variable "type_handler_version" {
  type        = string
  description = "Type handler version of the VM extension to use. Defaults to 2.2 on Windows and 1.1 on Linux"
  default     = null
}

variable "ipconfig_name" {
  type        = string
  description = "Name of ipconfig if applicable. Defaults to ipconfig01."
  default     = "ipconfig01"
}

variable "maintenance_configuration_id" {
  type        = string
  default     = null
  description = "The ID of the Maintenance Configuration to use for this Virtual Machine. patch_mode must be set to AutomaticByPlatform."
}

variable "custom_script_extension" {
  type = object({
    command_to_execute     = string
    script_urls            = list(string)
    rerun_script_extension = optional(number, 0)
  })
  default     = null
  description = "Run a custom script on VM. See https://learn.microsoft.com/en-us/azure/virtual-machines/extensions/custom-script-windows for more information. Also works for Linux VMs."
}

variable "avd_register_session_host" {
  type = object({
    #     # https://github.com/Azure/RDS-Templates/blob/master/ARM-wvd-templates/DSC/Configuration.zip (requires fw opening)
    # https://github.com/Azure/RDS-Templates/issues/790
    # Finding the latest extension version can be done via Azure Portal --> AVD quickstart --> View template
    module_url              = optional(string, "https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_1.0.02790.438.zip")
    host_pool_name          = string
    registration_info_token = string
    aad_join                = optional(bool, true)
  })
  default     = null
  description = "Register VM to a host pool. Only works for Windows VMs and it needs to be aad joined"
}

variable "managed_identity_roles" {
  type = map(object({
    role_definition_name = string
    scope                = string
  }))
  default     = {}
  description = "List of roles to assign to the managed identity"
}

variable "additional_capabilities" {
  type = object({
    ultra_ssd_enabled   = optional(bool, false)
    hibernation_enabled = optional(bool, true)
  })
  default     = null
  description = "Additional capabilities for the VM"
}

variable "secure_boot_enabled" {
  type        = bool
  description = "Enable or disable Secure Boot for the VM."
  default     = true
}

variable "vtpm_enabled" {
  type        = bool
  description = "Enable or disable Virtual Trusted Platform Module (vTPM) for the VM."
  default     = true
}

variable "disk_controller_type" {
  type        = string
  description = "The disk controller type for the VM. Possible values are 'SCSI' and 'NVMe'. Defaults to 'SCSI'."
  default     = null
  validation {
    condition     = var.disk_controller_type == "SCSI" || var.disk_controller_type == "NVMe" || var.disk_controller_type == null
    error_message = "disk_controller_type must be either 'SCSI' or 'NVMe'"
  }

}
