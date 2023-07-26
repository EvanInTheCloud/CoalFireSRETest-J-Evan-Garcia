resource "aws_db_subnet_group" "rds-subnet-group" {
  description = "High Availability Subnet group"
  name        = "rds-subnet-group"
  subnet_ids  = [module.vpc.private_subnets[3], module.vpc.private_subnets[2]]
}



module "RDS1" {
  source = "terraform-aws-modules/rds/aws"

  identifier = "rds1"

  engine            = "postgres"
  engine_version    = "11"
  instance_class    = "db.t3.micro"
  family            = "postgres14"
  allocated_storage = 5

  db_name  = "rds1"
  username = "coalfire"
  port     = "5432"

  iam_database_authentication_enabled = true

  vpc_security_group_ids = [resource.aws_security_group.db-sg.id]
  db_subnet_group_name   = resource.aws_db_subnet_group.rds-subnet-group.name

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"


  tags = {
    Owner       = "CoalFire001"
    Environment = "production"
  }


  # Database Deletion Protection
  deletion_protection = true

  options = [
    {
      option_name = "MARIADB_AUDIT_PLUGIN"

      option_settings = [
        {
          name  = "SERVER_AUDIT_EVENTS"
          value = "CONNECT"
        },
        {
          name  = "SERVER_AUDIT_FILE_ROTATIONS"
          value = "37"
        },
      ]
    },
  ]
}