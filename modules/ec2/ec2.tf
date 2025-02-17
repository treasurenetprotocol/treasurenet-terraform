# 创建安全组 - available ssh
resource "aws_security_group" "available_ssh" {
  name        = "available ssh"
  description = "available ssh"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["223.104.40.30/32"]
    description = "-"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["52.52.8.163/32"]
    description = "github"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["59.110.242.160/32"]
    description = "qiniu"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["1.119.195.66/32"]
    description = "trustlink"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["108.205.203.220/32"]
    description = "Andy"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 创建安全组 - test node
resource "aws_security_group" "test_node" {
  name        = "test node"
  description = "test node"

  ingress {
    from_port   = 1318
    to_port     = 1318
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "-"
  }

  ingress {
    from_port   = 26660
    to_port     = 26660
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "cosmos sdk"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "http"
  }

  ingress {
    from_port   = 1317
    to_port     = 1317
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "-"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "https"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 创建安全组 - testnet internal network
resource "aws_security_group" "testnet_internal_network" {
  name        = "testnet internal network"
  description = "testnet internal network"

  ingress {
    from_port   = 8545
    to_port     = 8545
    protocol    = "tcp"
    cidr_blocks = ["172.31.0.0/16"]
    description = "-"
  }

  ingress {
    from_port   = 26656
    to_port     = 26656
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "-"
  }

  ingress {
    from_port   = 8555
    to_port     = 8555
    protocol    = "tcp"
    cidr_blocks = ["172.31.0.0/16"]
    description = "-"
  }

  ingress {
    from_port   = 3000
    to_port     = 3050
    protocol    = "tcp"
    cidr_blocks = ["172.31.0.0/16"]
    description = "-"
  }

  ingress {
    from_port   = 1317
    to_port     = 1317
    protocol    = "tcp"
    cidr_blocks = ["172.31.0.0/16"]
    description = "-"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 创建安全组 - testnet services port
resource "aws_security_group" "testnet_services_port" {
  name        = "testnet services port"
  description = "testnet services port"

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "https"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "http"
  }

  ingress {
    from_port   = 3000
    to_port     = 3100
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "services"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
# 创建空安全组 blockscout1
resource "aws_security_group" "blockscout1" {
  name        = "blockscout1"
  description = "Empty SG for blockscout1"
  

}

# 创建空安全组 blockscout2
resource "aws_security_group" "blockscout2" {
  name        = "blockscout2"
  description = "Empty SG for blockscout2"

}
# blockscout1 的入站规则（允许来自 blockscout2 的 5432 流量）
resource "aws_security_group_rule" "blockscout1_ingress" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.blockscout2.id
  security_group_id        = aws_security_group.blockscout1.id
}

# blockscout2 的出站规则（允许流向 blockscout1 的 5432 流量）
resource "aws_security_group_rule" "blockscout2_egress" {
  type                     = "egress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.blockscout2.id
  source_security_group_id = aws_security_group.blockscout1.id
}



# 创建 EC2 实例
resource "aws_instance" "app_server" {
  for_each = {
    node0      = { ami = "ami-0ff591da048329e00", instance_type = "m6a.large", key_name = "testnet", root_volume_size = 200, root_volume_type = "gp3", name = "node0", role = "validator", security_groups = [aws_security_group.available_ssh.name, aws_security_group.test_node.name, aws_security_group.testnet_internal_network.name] },
    node1      = { ami = "ami-0ff591da048329e00", instance_type = "m6a.large", key_name = "testnet", root_volume_size = 200, root_volume_type = "gp3", name = "node1", role = "validator", security_groups = [aws_security_group.available_ssh.name, aws_security_group.test_node.name, aws_security_group.testnet_internal_network.name] },
    node2      = { ami = "ami-0ff591da048329e00", instance_type = "m6a.large", key_name = "testnet", root_volume_size = 200, root_volume_type = "gp3", name = "node2", role = "validator", security_groups = [aws_security_group.available_ssh.name, aws_security_group.test_node.name, aws_security_group.testnet_internal_network.name] },
    node3      = { ami = "ami-0ff591da048329e00", instance_type = "m6a.large", key_name = "testnet", root_volume_size = 200, root_volume_type = "gp3", name = "node3", role = "validator", security_groups = [aws_security_group.available_ssh.name, aws_security_group.test_node.name, aws_security_group.testnet_internal_network.name] },
    seednode0  = { ami = "ami-0ff591da048329e00", instance_type = "m6a.large", key_name = "testnet", root_volume_size = 200, root_volume_type = "gp3", name = "seednode0", role = "seed", security_groups = [aws_security_group.available_ssh.name, aws_security_group.test_node.name, aws_security_group.testnet_internal_network.name] },
    blockscout = { ami = "ami-0ff591da048329e00", instance_type = "m6a.large", key_name = "testnet", root_volume_size = 200, root_volume_type = "gp3", name = "blockscout", role = "explorer", security_groups = [aws_security_group.available_ssh.name, aws_security_group.testnet_services_port.name, aws_security_group.testnet_internal_network.name, aws_security_group.blockscout2.name,] }
  }

  ami           = each.value.ami
  instance_type = each.value.instance_type
  key_name      = each.value.key_name
  vpc_security_group_ids = each.value.security_groups

  root_block_device {
    volume_size = each.value.root_volume_size
    volume_type = each.value.root_volume_type
  }

  user_data = data.template_file.instance_user_data[each.key].rendered

  tags = {
    Name = each.value.name
    Role = each.value.role
  }
}

# 生成 user_data
data "template_file" "instance_user_data" {
  for_each = {
    node0      = { instance_index = 1, env_var = "ENV_VAR_1", docker_compose_version = "2.20.2" },
    node1      = { instance_index = 2, env_var = "ENV_VAR_2", docker_compose_version = "2.20.2" },
    node2      = { instance_index = 3, env_var = "ENV_VAR_3", docker_compose_version = "2.20.2" },
    node3      = { instance_index = 4, env_var = "ENV_VAR_4", docker_compose_version = "2.20.2" },
    seednode0  = { instance_index = 5, env_var = "ENV_VAR_5", docker_compose_version = "2.20.2" },
    blockscout = { instance_index = 6, env_var = "ENV_VAR_6", docker_compose_version = "2.20.2" }
  }

  template = file("${path.module}/configuration.sh")
  vars = {
    instance_index         = each.value.instance_index
    env_var                = each.value.env_var
    DOCKER_COMPOSE_VERSION = each.value.docker_compose_version
  }
}
