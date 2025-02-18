# 输出 EC2 实例的 ID 和公有 IP
output "ec2_instances" {
  description = "EC2 实例的 ID 和公有 IP"
  value = {
    for k, instance in aws_instance.app_server : k => {
      id         = instance.id
      public_ip  = instance.public_ip
      private_ip = instance.private_ip
    }
  }
}

# 输出安全组的 ID 和名称
output "security_groups" {
  description = "安全组的 ID 和名称"
  value = {
    available_ssh = {
      id   = aws_security_group.available_ssh.id
      name = aws_security_group.available_ssh.name
    }
    test_node = {
      id   = aws_security_group.test_node.id
      name = aws_security_group.test_node.name
    }
    testnet_internal_network = {
      id   = aws_security_group.testnet_internal_network.id
      name = aws_security_group.testnet_internal_network.name
    }
    testnet_services_port = {
      id   = aws_security_group.testnet_services_port.id
      name = aws_security_group.testnet_services_port.name
    }
  }
}

# 输出每个实例的安全组信息
output "instance_security_groups" {
  description = "每个实例关联的安全组"
  value = {
    for k, instance in aws_instance.app_server : k => {
      id         = instance.id
      security_groups = instance.vpc_security_group_ids
    }
  }
}

output "app_server_public_ips" {
  description = "EC2 实例的 Name 标签和公有 IP 的映射"
  value = {
    for instance in aws_instance.app_server : instance.tags.Name => instance.public_ip
  }
}
output "blockscout_public_ip" {
  description = "The public IP address of the blockscout instance"
  value       = aws_instance.app_server["blockscout"].public_ip
}
output "blockscout1_sg_id" {
  description = "blockscout1 安全组 ID"
  value       = aws_security_group.blockscout1.id
}