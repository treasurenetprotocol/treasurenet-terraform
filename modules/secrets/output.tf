output "db_password" {
  value = local.db_password  # 将本地值暴露为输出
  sensitive = true           # 标记为敏感值，防止在日志中泄露
}

output "cloudflare_token" {
  value = local.cloudflare_token  # 将本地值暴露为输出
  sensitive = true           # 标记为敏感值，防止在日志中泄露
}