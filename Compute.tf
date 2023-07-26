##Create bastion host####

resource "aws_instance" "bastion1" {
  ami                         = "ami-08ac82eb49891fee2"
  instance_type               = "t3a.medium"
  subnet_id                   = "subnet-0ca8dce3864151e90"
  key_name                    = "CoalFireKey001"
  associate_public_ip_address = true
  get_password_data           = true
  vpc_security_group_ids      = [resource.aws_security_group.bastion1-sg.id]
  root_block_device {
    volume_size = 50
  }

  tags = {
    Name = "bastion1"
  }
}


## EC2 Bastion Host Elastic IP
resource "aws_eip" "ec2-bastion-host-eip" {
  domain   = "vpc"
  instance = aws_instance.bastion1.id
  tags = {
    Name = "bastion1-eip"
  }
  depends_on = [ resource.aws_instance.bastion1 ]
}

## EC2 Bastion Host Elastic IP Association
resource "aws_eip_association" "ec2-bastion-host-eip-association" {
  instance_id   = aws_instance.bastion1.id
  allocation_id = aws_eip.ec2-bastion-host-eip.id
  depends_on = [ resource.aws_instance.bastion1 ]
}


###Create web servers###

resource "aws_instance" "wpserver1" {
  ami                         = "ami-0dc8c969d30e42996"
  instance_type               = "t3a.micro"
  subnet_id                   = "subnet-0891536945a2e8e42"
  key_name                    = "CoalFireKey001"
  associate_public_ip_address = false
  vpc_security_group_ids      = [resource.aws_security_group.wpserver-sg.id]
  root_block_device {
    volume_size = 20
  }

  user_data = <<EOF
#!/bin/bash
sudo yum update -y
sudo yum install -y httpd
sudo systemctl start httpd
sudo systemctl enable httpd
sudo echo "<h1>Hello World from $(hostname -f)</h1>" > /var/www/html/index.html

EOF

  tags = {
    Name = "wpserver1"
  }
}


resource "aws_instance" "wpserver2" {
  ami                         = "ami-0dc8c969d30e42996"
  instance_type               = "t3a.micro"
  subnet_id                   = "subnet-084f90b5e46b07d3f"
  key_name                    = "CoalFireKey001"
  associate_public_ip_address = false
  vpc_security_group_ids      = [resource.aws_security_group.wpserver-sg.id]
  root_block_device {
    volume_size = 20
  }

  user_data = <<EOF
#!/bin/bash
sudo yum update -y
sudo yum install -y httpd
sudo systemctl start httpd
sudo systemctl enable httpd
sudo echo "<h1>Hello World from $(hostname -f)</h1>" > /var/www/html/index.html

EOF

  tags = {
    Name = "wpserver2"
  }
}

