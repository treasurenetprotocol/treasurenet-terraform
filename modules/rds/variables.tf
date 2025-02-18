variable "app_server_public_ips" {
  description = "EC2 实例的 Name 标签和公有 IP 的映射"
  type        = map(string)
}

variable "db_password" {
  type        = string
  description = "RDS 实例的密码"
}

variable "blockscout_public_ip" {
  type        = string
  description = "blockscout的公网ip"
}
variable "blockscout1_sg_id" {
  type        = string
  description = "blockscout的安全组id"
}
