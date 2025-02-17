
module "secrets" {
  source = "./modules/secrets"
}


module "ec2" {
  source = "./modules/ec2"
}

module "rds" {
  source = "./modules/rds"
  db_password = module.secrets.db_password
  app_server_public_ips = module.ec2.app_server_public_ips
  blockscout_public_ip = module.ec2.blockscout_public_ip
  blockscout1_sg_id = module.ec2.blockscout1_sg_id
}

module "dns" {
  source = "./modules/dns"
  app_server_public_ips = module.ec2.app_server_public_ips
 
}
