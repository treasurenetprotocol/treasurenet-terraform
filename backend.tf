 #backend.tf
 terraform {
   backend "s3" {
     bucket = "testnet-terraform"
     key    = "terraform.tfstate"
     region = "us-west-1"
   }
 }
