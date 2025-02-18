variable "app_server_public_ips" {
  description = "EC2 实例的 Name 标签和公有 IP 的映射"
  type        = map(string)
}
