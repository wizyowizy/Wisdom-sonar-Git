variable "my_ip" {
   description = "My Static IP address"
   type = string
   sensitive = true
}

variable "region" {
   description = "Define the region where AWS service is provisioned"
   default = "us-east-1"
   }
