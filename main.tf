provider "aws" {
  region = "us-west-1"
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 使用 count 参数创建多个实例
resource "aws_instance" "app_server" {
  count         = 4
  ami           = "ami-0ff591da048329e00"
  instance_type = "t2.micro"
  key_name      = "testnet"

  security_groups = [aws_security_group.allow_ssh.name]

  # 配置 EBS 磁盘大小
  root_block_device {
    volume_size = 200  # 磁盘大小为 200GB
    volume_type = "gp3"  # 磁盘类型为通用 SSD (gp3)
  }

  # 动态生成每个 EC2 实例的 user_data
  user_data = data.template_file.instance_user_data[count.index].rendered

  tags = {
    Name = "ExampleAppServerInstance${count.index + 1}"
    Role = "validator"
  }

  lifecycle {
    prevent_destroy = false
  }
}

# 动态生成每个实例的环境变量配置
data "template_file" "instance_user_data" {
  count    = 4
  template = file("${path.module}/1.sh")

  vars = {
    instance_index = count.index + 1
    env_var        = "ENV_VAR_${count.index + 1}"
    DOCKER_COMPOSE_VERSION = "2.20.2"
  }
}

output "instance_ips" {
  value = [
    for server in aws_instance.app_server : server.public_ip
  ]
}
