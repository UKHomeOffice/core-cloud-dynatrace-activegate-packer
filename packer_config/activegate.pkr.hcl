packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.8"
      source  = "github.com/hashicorp/amazon"
    }
    ansible = {
      version = ">= 1.1.1"
      source  = "github.com/hashicorp/ansible"
    }
  }
}

source "amazon-ebs" "dt_activegate" {
  ami_name      = local.amiName
  instance_type = var.instanceType
  region        = var.awsRegion

  source_ami_filter {
    filters = var.baseAMIFilter.filters
    most_recent = var.baseAMIFilter.most_recent
    owners      = var.baseAMIFilter.owners
  }
  
  communicator = "ssh"
  ssh_interface = "session_manager"
  iam_instance_profile = var.ssmRoleName
  ssh_username = var.baseAMISSHUserName
  tags = merge(var.amiTags, var.amiTypeTag, {Name: local.amiName})

  launch_block_device_mappings {
    device_name = "/dev/sda1"
    encrypted = true
    kms_key_id = var.kmsKeyId
  }

  skip_create_ami = var.skipAmiCreate
}

build {
  name    = local.amiName
  sources = [
    "source.amazon-ebs.dt_activegate"
  ]
  provisioner "ansible" {
    playbook_file = "ansible/install_activegate.yml"
    use_proxy =  false
    inventory_file_template =  "{{ .HostAlias }} ansible_host={{ .ID }} ansible_user={{ .User }} ansible_ssh_common_args='-o StrictHostKeyChecking=no -o ProxyCommand=\"sh -c \\\"aws ssm start-session --target %h --document-name AWS-StartSSHSession --parameters portNumber=%p\\\"\"'\n"
    extra_arguments = [
      "--extra-vars", "activegate_version=${var.activeGateVersion}",
      "--extra-vars", "ansible_aws_ssm_region=${var.awsRegion}",
      "--extra-vars", "instance_architecture=${var.amiArch}",
      "--extra-vars", "aws_secret_name=${var.dynatraceSecretName}",
      "--extra-vars", "{skip_image_upgrade: ${var.skipImageUpgrade}}"
    ]
  }
}
