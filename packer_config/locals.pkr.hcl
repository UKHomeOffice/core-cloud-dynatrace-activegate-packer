locals {
  amiName = "${var.amiPrefix}_${var.semVer}_${length(var.activeGateVersion) <=0 ? "latest":var.activeGateVersion}_${formatdate("YYYYMMDDhhmmss",timestamp())}"
}