data "aws_secretsmanager_secret" "main" {
  name = "testnet/treasurenet-terraform"
}

data "aws_secretsmanager_secret_version" "main" {
  secret_id = data.aws_secretsmanager_secret.main.id
}

locals {
  secrets       = jsondecode(data.aws_secretsmanager_secret_version.main.secret_string)
  db_password   = local.secrets["db_password"]
  cloudflare_token = local.secrets["cloudflare_token"]
}
