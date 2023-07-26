module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "CoalFireVPC"
  cidr = "10.1.0.0/16"

  azs             = ["us-west-1b", "us-west-1c"]
  private_subnets = ["10.1.2.0/24", "10.1.3.0/24", "10.1.4.0/24", "10.1.5.0/24"]
  public_subnets  = ["10.1.0.0/24", "10.1.1.0/24"]

  flow_log_file_format = "plain-text"


  tags = {
    Terraform   = "true"
    Environment = "prod"
  }

}

###Create Security Groups###

resource "aws_security_group" "bastion1-sg" {
  name        = "bastion1-sg"
  description = "Allow RDP inbound traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "RDP from my IP"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "bastion1-sg"
  }
}

resource "aws_security_group" "alb-sg" {
  name        = "alb-sg"
  description = "Application LB SG"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "HTTPS from web"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTP from web"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "alb-sg"
  }
}

resource "aws_security_group" "wpserver-sg" {
  name        = "wpserver-sg"
  description = "Allow HTTPS inbound traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "HTTPS from alb"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.1.0.0/24", "10.1.1.0/24"]
  }
  ingress {
    description = "HTTP from web"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.1.0.0/24", "10.1.1.0/24"]

  }
  ingress {
    description = "SSH from bastion"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.1.0.0/24"]

  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "wpserver-sg"
  }
}



resource "aws_security_group" "db-sg" {
  name        = "db-sg"
  description = "Allow postgres"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "DbTraffic from wpservers"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.1.2.0/24", "10.1.3.0/24"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "db-sg"
  }
}

#####################################
##### Application Load Balanceer####

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 8.0"

  name = "my-alb"

  load_balancer_type = "application"

  vpc_id          = module.vpc.vpc_id
  subnets         = ["subnet-0891536945a2e8e42", "subnet-084f90b5e46b07d3f"]
  security_groups = [resource.aws_security_group.alb-sg.id]

  # Target Groups
  target_groups = [
    # App1 Target Group
    {
      name_prefix      = "WPS-"
      backend_protocol = "HTTP"
      backend_port     = 80
      target_type      = "instance"
      health_check = {
        enabled             = true
        interval            = 15
        path                = "/var/www/html/index.html"
        port                = "traffic-port"
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout             = 6
        protocol            = "HTTP"
        matcher             = "200-399"
      },      
      protocol_version = "HTTP1"
      # App1 Target Group - Targets
      targets = {
        my_app1_vm1 = {
          target_id = resource.aws_instance.wpserver1.id
          port      = 80
        },
        my_app1_vm2 = {
          target_id = resource.aws_instance.wpserver2.id
          port      = 80
        }        
      }
      tags = "ALB"
    }     
  ]

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
    }
  ]

  tags = {
    Environment = "Test"
  }

  depends_on = [ resource.aws_security_group.alb-sg, resource.aws_instance.wpserver1,  resource.aws_instance.wpserver2]
}
