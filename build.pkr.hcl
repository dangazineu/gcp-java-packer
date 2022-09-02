variable "project_id" {
  type = string
}

variable "builder_sa" {
  type = string
}

source "googlecompute" "src-image" {
  project_id                  = var.project_id
  source_image_family         = "debian-11"
  zone                        = "us-central1-a"
  image_description           = "Created with Packer from Cloud Build"
  ssh_username                = "packer"
  tags                        = ["packer-java"]
  impersonate_service_account = var.builder_sa
}

build {
  sources = ["sources.googlecompute.src-image"]
  name = "debian11-with-java"
  provisioner "shell" {
    script = "install_temurin.sh"
  }
}