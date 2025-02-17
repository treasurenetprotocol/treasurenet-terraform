resource "aws_default_vpc" "default" {}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [aws_default_vpc.default.id]
  }
}

resource "aws_db_subnet_group" "production_db_1" {
  name       = "production-db-subnet-group_1"
  subnet_ids = data.aws_subnets.default.ids
}



resource "aws_db_instance" "blockscout_db" {
  identifier           = "testnet-blockscout"
  engine               = "postgres"
  engine_version       = "12.19"
  instance_class       = "db.t3.large"
  allocated_storage    = 200
  storage_type         = "gp3"
  username             = "postgres"
  password             = var.db_password # 使用从 Secrets Manager 获取的密码
  parameter_group_name = "default.postgres12"
  skip_final_snapshot  = true
  publicly_accessible  = false
  vpc_security_group_ids = [var.blockscout1_sg_id]
  db_subnet_group_name = aws_db_subnet_group.production_db_1.name
  db_name              = "blockscout"
}




data "aws_secretsmanager_secret_version" "existing_secret" {
  secret_id = "testnet/blockscout/blockscout"
}

resource "aws_secretsmanager_secret_version" "blockscout_db_secret_version" {
  secret_id = data.aws_secretsmanager_secret_version.existing_secret.secret_id
  secret_string = jsonencode(
    merge(
      jsondecode(data.aws_secretsmanager_secret_version.existing_secret.secret_string),
      {
        DATABASE_URL = "postgresql://${aws_db_instance.blockscout_db.username}:${aws_db_instance.blockscout_db.password}@${aws_db_instance.blockscout_db.endpoint}/${aws_db_instance.blockscout_db.db_name}"
      }
    )
  )
}