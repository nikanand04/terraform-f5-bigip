variable "address" {}
variable "username" {}
variable "password" {}
variable "as3_rpm" {
  default = "f5-appsvcs-3.21.0-4.noarch.rpm"
}
variable "as3_rpm_url" {
  default = "https://github.com/F5Networks/f5-appsvcs-extension/releases/download/v3.21.0/f5-appsvcs-3.21.0-4.noarch.rpm"
}
variable "do_rpm" {
  default = "f5-declarative-onboarding-1.14.0-1.noarch.rpm"
}
variable "do_rpm_url" {
  default = "https://github.com/F5Networks/f5-declarative-onboarding/releases/download/v1.14.0/f5-declarative-onboarding-1.14.0-1.noarch.rpm"
}