locals {
  amiName = "${var.amiPrefix}-${length(var.activeGateVersion) <=0 ? "latest":var.activeGateVersion}-${formatdate("YYYYMMDDhhmmss",timestamp())}"
}