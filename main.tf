terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0" # 指定你需要的版本
    }
  }
}

variable "cloudflare_api_token" {
  type = string
}
provider "aws" {
  region = "us-west-1"
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}


# 使用默认 VPC
resource "aws_default_vpc" "default" {}

# 获取默认 VPC 中的所有子网
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [aws_default_vpc.default.id]
  }
}

# 创建子网组
resource "aws_db_subnet_group" "production_db" {
  name       = "production-db-subnet-group"
  subnet_ids = data.aws_subnets.default.ids
}

# 创建 RDS 实例
resource "aws_db_instance" "blockscout_db" {
  identifier           = "testnet-blockscout"
  engine               = "postgres"
  engine_version       = "12.19"
  instance_class       = "db.t3.large"
  allocated_storage    = 200
  storage_type         = "gp3"
  username             = "postgres"
  password             = "XX6uQmKRKwXNFzN1Ypid" # 替换为你的密码
  parameter_group_name = "default.postgres12"
  skip_final_snapshot  = true
  publicly_accessible  = false
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name = aws_db_subnet_group.production_db.name
  db_name              = "blockscout" # 数据库名称
}

# 创建安全组
resource "aws_security_group" "rds_sg" {
  name_prefix = "rds-sg-"

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # 允许所有 IP 访问（生产环境应限制为特定 IP）
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 使用现有的 Secrets Manager Secret
data "aws_secretsmanager_secret_version" "existing_secret" {
  secret_id = "testnet/blockscout/blockscout"
}

# 创建 Secrets Manager Secret 版本
resource "aws_secretsmanager_secret_version" "blockscout_db_secret_version" {
  secret_id = data.aws_secretsmanager_secret_version.existing_secret.secret_id
  secret_string = jsonencode(
    merge(
      # 保留所有现有字段
      jsondecode(data.aws_secretsmanager_secret_version.existing_secret.secret_string), {
        DATABASE_URL = "postgresql://${aws_db_instance.blockscout_db.username}:${aws_db_instance.blockscout_db.password}@${aws_db_instance.blockscout_db.endpoint}/${aws_db_instance.blockscout_db.db_name}"
      }
    )
  )
}


# 创建 EC2 实例
resource "aws_instance" "app_server" {
  count         = 6
  ami           = "ami-0ff591da048329e00"
  instance_type = "m6a.large"
  key_name      = "testnet"

  # 使用不同的安全组配置
  vpc_security_group_ids = count.index == 5 ? [
    "sg-0ab37516af9813a5f",  // Allow specific developers to log in via SSH.
    "sg-0cc06e31de5e2e841",  // The connectivity of the intranet port.
    "sg-00af264f4b988cb87"   // The port used for the service.
  ] : [
    "sg-0d2ea4db73de54ad9",  // The port dedicated to the node.
    "sg-0ab37516af9813a5f",  // Allow specific developers to log in via SSH.
    "sg-0cc06e31de5e2e841"   // The connectivity of the intranet port.
  ]

  root_block_device {
    volume_size = 200
    volume_type = "gp3"
  }

  user_data = <<-EOF
#!/bin/bash
# 执行 configuration.sh
${data.template_file.instance_user_data[count.index].rendered}
EOF

  tags = {
    Name = count.index == 4 ? "seednode0" : (count.index == 5 ? "blockscout" : "node${count.index}")
    Role = count.index == 4 ? "seed" : (count.index == 5 ? "explorer" : "validator")
  }
}

data "template_file" "instance_user_data" {
  count    = 6
  template = file("${path.module}/configuration.sh")

  vars = {
    instance_index         = count.index + 1
    env_var                = "ENV_VAR_${count.index + 1}"
    DOCKER_COMPOSE_VERSION = "2.20.2"
  }
}

# 输出 EC2 实例的详细信息
output "instance_details" {
  value = [
    for instance in aws_instance.app_server : {
      public_ip  = instance.public_ip
      private_ip = instance.private_ip
      name       = instance.tags.Name
    }
  ]
}


# 获取 Cloudflare 区域信息
data "cloudflare_zone" "host" {
  name = "treasurenet.io" # 替换为你的域名
}
locals {
  # 基础配置参数
  node_count    = 4  # 生成 node0-node3
  service_types = ["monitoring", "cosmosapi", "tm-mtrcs"]

  # 动态生成所有节点记录（使用索引代替字符串键）
  node_records = merge([
    for idx in range(local.node_count) : {
      # 根据实例命名规则，node0-node3对应索引0-3
      "monitoring.node${idx}" = {
        name    = "monitoring.node${idx}"
        ip      = aws_instance.app_server[idx].public_ip
        proxied = true
      }
      "cosmosapi.node${idx}" = {
        name    = "cosmosapi.node${idx}"
        ip      = aws_instance.app_server[idx].public_ip
        proxied = true
      }
      "tm-mtrcs.node${idx}" = {
        name    = "tm-mtrcs.node${idx}"
        ip      = aws_instance.app_server[idx].public_ip
        proxied = true
      }
    }
  ]...)

  # 特殊种子节点记录（索引4对应seednode0）
  seednode_record = {
    "monitoring.seednode0" = {
      name    = "monitoring.seednode0"
      ip      = aws_instance.app_server[4].public_ip
      proxied = true
    }
  }
}


# 创建或更新 DNS 记录
resource "cloudflare_record" "dns_records" {
  for_each = merge(
    # 原有实例映射
    { for idx, instance in aws_instance.app_server : instance.tags.Name => instance },
    local.node_records,
    local.seednode_record,
    # 新增 evmexplorer 映射
    {
      # EVM 浏览器相关
      "evmexplorer" = {
        name    = "evmexplorer"
        ip      = [for k, v in aws_instance.app_server : v.public_ip if v.tags.Name == "blockscout"][0]
        proxied = true
      }
          
      "evmexplorer.stats" = {
        name    = "evmexplorer.stats"
        ip      = [for k, v in aws_instance.app_server : v.public_ip if v.tags.Name == "blockscout"][0]
        proxied = true
      },
      "evmexplorer.va" = {
        name    = "evmexplorer.va"
        ip      = [for k, v in aws_instance.app_server : v.public_ip if v.tags.Name == "blockscout"][0]
        proxied = true
      },
      "monitoring.e-explorer" = {
        name    = "monitoring.e-explorer"
        ip      = [for k, v in aws_instance.app_server : v.public_ip if v.tags.Name == "blockscout"][0]
        proxied = true
      },
    }
  )

  zone_id = data.cloudflare_zone.host.id
  name    = contains(["blockscout", "seednode0"], each.key) ? "${split("_", each.key)[0]}.testnet" : "${each.key}.testnet"
  value   = try(each.value.public_ip, each.value.ip) # 兼容两种数据源
  type    = "A"
  proxied = try(each.value.proxied, true) # 默认启用代理
  ttl     = 1
}
