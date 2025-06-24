module "vpc" {
  source        = "./modules/vpc"
  network_name  = "javdes-network"
  subnet_name   = "javdes-subnet"
  subnet_cidr   = "10.240.0.0/24"
  region        = var.region
}

module "vm" {
  source          = "./modules/vm"
  project         = var.project
  region          = var.region
  zone            = var.zone
  network_name    = module.vpc.network_name
  subnet_name     = module.vpc.subnet_name
  public_key_path = "~/.ssh/gcp_javdes.pub"
}