provider "aws" {
  region = "us-west-2"
}

module "ec2_instance" {
  source = "../modules/ec2"

  instance_name  = "k8s-node"
  ami_id         = "ami-00c257e12d6828491"
  instance_type  = "t2.medium"
  key_name       = "techiescamp"
  subnet_ids     = ["subnet-0f92233e44d3044ef", "subnet-007ab506046047319", "subnet-006538decc4e58a2e"]
  instance_count = 3

inbound_from_port  = ["0", "6443", "22", "30000", "0"]
inbound_to_port    = ["65000", "6443", "22", "32768", "65000"]
inbound_protocol   = ["TCP", "TCP", "TCP", "TCP", "TCP"]
inbound_cidr       = ["172.31.0.0/16", "0.0.0.0/0", "0.0.0.0/0", "0.0.0.0/0", "10.244.0.0/16"]
outbound_from_port = ["0"]
outbound_to_port   = ["0"]
outbound_protocol  = ["-1"]
outbound_cidr      = ["0.0.0.0/0"]
}
