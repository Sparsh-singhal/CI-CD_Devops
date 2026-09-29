
# resource "aws_vpc" "main" { // create a vpc virtual private cloud
#   cidr_block = "10.1.0.0/16"
#     tags = {
#         Name = "main-vpc"
#     }   
# }    

# resource "aws_subnet" "main" { // create a subnet inside the vpc
#   vpc_id                  = aws_vpc.main.id
#   cidr_block              = "10.1.1.0/24"
#   map_public_ip_on_launch = true

#   tags = {
#     Name = "main-subnet"
#   }
# }

# resource "aws_internet_gateway" "main" { // create a internet gateway to allow internet access for the vpc so that we can accesss it
#   vpc_id = aws_vpc.main.id

#   tags = {
#     Name = "main-igw"
#   }
# }

# resource "aws_route_table" "main" { // this will create a route table for the vpc and we will associate it with the subnet so that the subnet can access the internet
#   vpc_id = aws_vpc.main.id

#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_internet_gateway.main.id
#   }

#   tags = {
#     Name = "main-rt"
#   }
# }

# resource "aws_route_table_association" "main" { // this will associate the route table with the subnet so that the subnet can access the internet
#   subnet_id      = aws_subnet.main.id
#   route_table_id = aws_route_table.main.id
# }

# resource "aws_security_group" "ssh_web" { // creating a security grp 
#   name        = "allow-ssh-http"
#   description = "Allow SSH and http inbound"
#   vpc_id      = aws_vpc.main.id

#   ingress { // inbound rule for ec2
#     description = "SSH"
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   ingress { // inbound rule for ec2
#     description = "HTTP"
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   egress { // outbound rule for ec2
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     Name = "allow-ssh-http"
#   }
# }

# resource "aws_key_pair" "demo" { //ssh key to access it
#   # ssh-keygen -y -f Demo.pem > Demo.pem.pub
#   key_name   = "Demo_cs"
#   public_key = file("Demo_cs.pem.pub")
# }

# # data "aws_ami" "ubuntu" {
# #   most_recent = true
# #   owners      = ["099720109477"] # Canonical

# #   filter {
# #     name   = "name"
# #     values = ["ubuntu/images/hvm-ssd/ubuntu-resolute-26.04-amd64-server-*"]
# #   }
# # }

# resource "aws_instance" "demo" { // ec2 instance
#   ami                    = "ami-0b6d9d3d33ba97d99"
#   instance_type          = "t3.micro"
#   subnet_id              = aws_subnet.main.id
#   key_name               = aws_key_pair.demo.key_name
#   vpc_security_group_ids = [aws_security_group.ssh_web.id]
#   user_data = <<-EOF
#               #!/bin/bash
#               sudo apt update -y
#               sudo apt install nginx -y
#               echo "Hello world"> /var/www/html/index.html
#               systemctl enable nginx
#               systemctl start nginx
#             EOF

#   tags = {
#     Name = "demo-instance"
#   }
# }

# output "public_ip" {// public ip of ec2
#   description = "Public IP of the EC2 instance"
#   value       = aws_instance.demo.public_ip
# }


resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret" "db_secret" {
  name        = "demo/rds/postgres"
  description = "RDS PostgreSQL credentials created using Terraform"
}

resource "aws_secretsmanager_secret_version" "db_secret_value" {
  secret_id = aws_secretsmanager_secret.db_secret.id

  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db_password.result
    engine   = "postgres"
    dbname   = var.db_name
  })
}

resource "aws_security_group" "rds_sg" {
  name        = "demo-postgres-rds-sg"
  description = "Allow PostgreSQL access"

  ingress {
    from_port   = 5432
    to_port     = 5432
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

resource "aws_db_instance" "postgres_db" {
  identifier             = "demo-postgres-db"
  allocated_storage      = 20
  db_name                = var.db_name
  engine                 = "postgres"
  engine_version         = "16"
  instance_class         = "db.t3.micro"
  username               = var.db_username
  password               = random_password.db_password.result
  publicly_accessible    = true
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
} 