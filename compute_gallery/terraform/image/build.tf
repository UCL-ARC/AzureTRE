resource "azapi_resource" "image_template" {
  type      = "Microsoft.VirtualMachineImages/imageTemplates@2020-02-14"
  name      = "template-${var.image_identifier}"
  parent_id = data.azurerm_resource_group.compute_gallery.id
  location  = var.location

  body = jsonencode({
    identity = {
      type = "UserAssigned"
      userAssignedIdentities = {
        tostring(var.image_builder_id) = {}
      }
    }
    properties = {
      buildTimeoutInMinutes = 180,

      vmProfile = {
        vmSize       = "Standard_DS2_v2",
        osDiskSizeGB = 30
      },

      source = {
        type      = "PlatformImage",
        publisher = var.base_image.publisher,
        offer     = var.base_image.offer,
        sku       = var.base_image.sku,
        version   = "latest"
      },
      customize = concat(
        [
          {
            type   = endswith(var.init_script, ".ps1") ? "PowerShell" : "Shell",
            name   = "setupVM",
            inline = split("\n", file(local.init_script_path))
          }
        ],
        fileexists(local.customize__file_path) ? jsondecode(file(local.customize__file_path)) : []
      ),
      distribute = [
        {
          type           = "SharedImage",
          galleryImageId = "${azurerm_shared_image.image.id}",
          runOutputName  = "${var.image_definition}",
          artifactTags = {
            source    = "azureVmImageBuilder",
            baseosimg = "${var.base_image.sku}"
          },
          replicationRegions = [var.location],
          storageAccountType = "Standard_LRS"
        }
      ]
  } })

  tags = {
    "useridentity" = "enabled"
  }

  # Avoid 409 Conflict by always replacing
  lifecycle {
    replace_triggered_by = [
      null_resource.always_run
    ]
  }
}

resource "null_resource" "always_run" {
  triggers = {
    timestamp = timestamp()
  }
}
