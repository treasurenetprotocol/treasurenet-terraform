provider "aws" {
  region = "us-west-1"
}

resource "aws_instance" "app_server" {
  count         = 5
  ami           = "ami-0ff591da048329e00"
  instance_type = "t2.micro"
  key_name      = "testnet"

  # 使用现有的安全组ID
  vpc_security_group_ids = ["sg-0cc06e31de5e2e841"]

  root_block_device {
    volume_size = 200
    volume_type = "gp3"
  }

  user_data = <<-EOF
    #!/bin/bash
    # 执行 1.sh
    ${data.template_file.instance_user_data[count.index].rendered}
  EOF

  tags = {
    Name = count.index == 4 ? "seednode" : "node${count.index + 1}"
    Role = count.index == 4 ? "seed" : "validator"
  }
}

data "template_file" "instance_user_data" {
  count    = 5
  template = file("${path.module}/1.sh")

  vars = {
    instance_index         = count.index + 1
    env_var                = "ENV_VAR_${count.index + 1}"
    DOCKER_COMPOSE_VERSION = "2.20.2"
  }
}

output "instance_details" {
  value = [
    for instance in aws_instance.app_server : {
      public_ip  = instance.public_ip
      private_ip = instance.private_ip
      name       = instance.tags.Name
    }
  ]
}
