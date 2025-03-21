variable "baseAMIFilter" {
  description = "A variable in which the parameter to filter the #AMI to be passed on for filtering the base AMI. This fully or #partially optional and will use default values as found below."
  type = object({
    filters = map(string)
    owners = list(string)
    most_recent = bool
  })
  default = {
    filters = {
      name = "ubuntu-minimal/images/hvm-ssd/ubuntu-jammy-22.04-arm64-minimal-*"
      root-device-type = "ebs"
      virtualization-type = "hvm"
    }
    owners = [
      "099720109477"
    ]
    most_recent = true
  }
}

variable "baseAMISSHUserName" {
  description = "User name to ssh into. This usually comes from the base AMI provider."
  type = string
  default = "ubuntu"
}

variable "amiPrefix" {
  description = "The string base of the new AMI name."
  type = string
  default = "cc-dt-ag"
}

variable "instanceType" {
  description = "AWS instance type of AMI. Please note that this is not going to be the instance size of the Activagate instance. This is just to build the AMI. Therefore, keep it to the minimum to save costs."
  type = string
  default = "m6g.medium" # Graviton
}

variable "awsRegion" {
  description = "Region into which the AMI to be built."
  type = string
  default = "eu-west-2"
}

variable "amiTags" {
  description = "Tags to be added to the AMI"
  type = map(string)
  default = {
    account-code = "521835"
    cost-centre  = "1709144"
    service-id   = "Dynatrace"
    portfolio-id = "CTO"
    project-id   = "CC"
  }
}

variable "amiTypeTag" {
  description = "Set of tags used to filter the activegate amis."
  type = map(string)
  default = {
    Type = "activegate-ami"
  }
}

variable "activeGateVersion" {
  description = "Activegate version to download. If not provided, 'latest' activegate will be downloaded."
  type = string
  default = ""
}

variable "amiArch" {
  description = "Architecutre of the machine to be built. Currently only amd64 and arm64 are supported. You may also have to adjust the filter parameters for the baseAMIFilter above."
  type = string
  default = "arm64"
}

variable "dynatraceSecretName" {
  description = "Name of the secret from which the dynatrace environment details to be retrieved from. The secret nust contain the keys 'dt_env_id', 'dt_tenant_token' and 'dt_auth_token' with valid values."
  type = string
  default = "dynatrace_tokens"
}

variable "kmsKeyId" {
  description="ID, alias or ARN of the KMS key to use for boot volume encryption. If not provided, default key will be used."
  type = string
  default = null
}

variable "ssmRoleName" {
  description = "Name of the SSM role using which connection to the instance, during the configuration/provisioning phase to be made."
  type = string
  default="EC2_SSM_Role"
}

variable "skipImageUpgrade" {
  description = "Whether to skip a full upgrade of the instance before installing the activegate. By default a full upgrade is performed."
  type = string
  default = "false"
}

variable "skipAmiCreate" {
  description = "A flag to be enabled during the testing of the packer build."
  type = bool
  default = false
}