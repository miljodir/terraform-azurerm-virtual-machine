locals {
  #Predefined images can be added here

  ## Linux ##
  linux_distribution_list = {
    ubuntu2404 = {
      publisher = "Canonical"
      offer     = "ubuntu-24_04-lts"
      sku       = "minimal" #"server" # TBD
      version   = "latest"
    }
    ubuntu2204 = {
      publisher = "Canonical"
      offer     = "0001-com-ubuntu-server-jammy"
      sku       = "22_04-lts-gen2"
      version   = "latest"
    }
    ubuntu2004 = {
      publisher = "Canonical"
      offer     = "0001-com-ubuntu-server-focal"
      sku       = "20_04-lts"
      version   = "latest"
    },
    centos81 = {
      publisher = "OpenLogic"
      offer     = "CentOS"
      sku       = "8_5"
      version   = "latest"
    },
    mssql2022ent-ubuntu2004 = {
      publisher = "MicrosoftSQLServer"
      offer     = "sql2022-ubuntu2004"
      sku       = "enterprise"
      version   = "latest"
    },
    mssql2022std-ubuntu2004 = {
      publisher = "MicrosoftSQLServer"
      offer     = "sql2022-ubuntu2004"
      sku       = "standard"
      version   = "latest"
    },
    mssql2022dev-ubuntu2004 = {
      publisher = "MicrosoftSQLServer"
      offer     = "sql2022-ubuntu2004"
      sku       = "sqldev"
      version   = "latest"
    }
  }

  ## Windows ##
  windows_distribution_list = {
    windows2025az = {
      publisher = "MicrosoftWindowsServer"
      offer     = "WindowsServer"
      sku       = "2025-datacenter-azure-edition"
      version   = "latest"
    }
    windows2025azsmall = {
      publisher = "MicrosoftWindowsServer"
      offer     = "WindowsServer"
      sku       = "2025-datacenter-azure-edition-smalldisk"
      version   = "latest"
    }
    windows2022azhotpatch = {
      publisher = "MicrosoftWindowsServer"
      offer     = "WindowsServer"
      sku       = "2022-datacenter-azure-edition-hotpatch"
      version   = "latest"
    },
    windows2022azhotpatchsmall = {
      publisher = "MicrosoftWindowsServer"
      offer     = "WindowsServer"
      sku       = "2022-datacenter-azure-edition-hotpatch-smalldisk"
      version   = "latest"
    },
    windows2022dc = {
      publisher = "MicrosoftWindowsServer"
      offer     = "WindowsServer"
      sku       = "2022-Datacenter"
      version   = "latest"
    },
    windows2022small = {
      publisher = "MicrosoftWindowsServer"
      offer     = "WindowsServer"
      sku       = "2022-Datacenter-smalldisk"
      version   = "latest"
    },
    windows2022core = {
      publisher = "MicrosoftWindowsServer"
      offer     = "WindowsServer"
      sku       = "2022-Datacenter-core"
      version   = "latest"
    },
    windows2019dc = {
      publisher = "MicrosoftWindowsServer"
      offer     = "WindowsServer"
      sku       = "2019-Datacenter"
      version   = "latest"
    },
    mssql2022std = {
      publisher = "MicrosoftSQLServer"
      offer     = "sql2022-ws2022"
      sku       = "standard"
      version   = "latest"
    },
    mssql2022dev = {
      publisher = "MicrosoftSQLServer"
      offer     = "sql2022-ws2022"
      sku       = "sqldev"
      version   = "latest"
    },
    mssql2022ent = {
      publisher = "MicrosoftSQLServer"
      offer     = "sql2022-ws2022"
      sku       = "enterprise"
      version   = "latest"
    },
    mssql2022ent-byol = {
      publisher = "MicrosoftSQLServer"
      offer     = "sql2022-ws2022-byol"
      sku       = "enterprise"
      version   = "latest"
    },
    mssql2022std-byol = {
      publisher = "MicrosoftSQLServer"
      offer     = "sql2022-ws2022-byol"
      sku       = "standard"
      version   = "latest"
    }
  }

  #This local value sets correct image based on OS flavor and var custom_image
  image = var.custom_image != null ? var.custom_image : (
    var.os_flavor == "windows" ?
    local.windows_distribution_list[var.windows_distribution_name] :
    local.linux_distribution_list[var.linux_distribution_name]
  )
}