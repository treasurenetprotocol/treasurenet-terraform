terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

data "cloudflare_zone" "host" {
  name = "treasurenet.io"
}

locals {
  # 从 ec2 模块传递的实例 Name 标签和公有 IP 的映射
  app_server_ips = var.app_server_public_ips

   node_dns_records = {
    for name, ip in local.app_server_ips :
    name => {
      name    = name
      ip      = ip
      proxied = true
    }
  }

  # 为每个节点生成 DNS 记录
  node_records = merge(
    {
      for name, ip in local.app_server_ips :
      "monitoring.${name}" => {
        name    = "monitoring.${name}"
        ip      = ip
        proxied = true
      }
    },
    {
      for name, ip in local.app_server_ips :
      "cosmosapi.${name}" => {
        name    = "cosmosapi.${name}"
        ip      = ip
        proxied = true
      }
    },
    {
      for name, ip in local.app_server_ips :
      "tm-mtrcs.${name}" => {
        name    = "tm-mtrcs.${name}"
        ip      = ip
        proxied = true
      }
    }
  )

  # Seednode 的 DNS 记录
  seednode_record = {
    "monitoring.seednode0" = {
      name    = "monitoring.seednode0"
      ip      = local.app_server_ips["seednode0"]
      proxied = true
    }
  }

  # Blockscout 的 DNS 记录
  blockscout_records = {
    "evmexplorer" = {
      name    = "evmexplorer"
      ip      = local.app_server_ips["blockscout"]
      proxied = true
    }
    "evmexplorer.stats" = {
      name    = "evmexplorer.stats"
      ip      = local.app_server_ips["blockscout"]
      proxied = true
    }
    "evmexplorer.va" = {
      name    = "evmexplorer.va"
      ip      = local.app_server_ips["blockscout"]
      proxied = true
    }
    "monitoring.e-explorer" = {
      name    = "monitoring.e-explorer"
      ip      = local.app_server_ips["blockscout"]
      proxied = true
    }
  }
}


resource "cloudflare_record" "dns_records" {
  for_each = merge(
    local.node_records,
    local.seednode_record,
    local.blockscout_records,
    local.node_dns_records
  )

  zone_id = data.cloudflare_zone.host.id
  name    = "${each.value.name}.testnet"  # 直接使用预定义的完整名称
  value   = each.value.ip
  type    = "A"
  proxied = try(each.value.proxied, true)
  ttl     = 1

  # 强制替换现有记录的关键参数
  lifecycle {
    create_before_destroy = true
  }
}



