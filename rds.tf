resource "aws_vpc" "db-vpc" {
  cidr_block       = "10.1.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = true
}

resource "aws_subnet" "subnet1" {
  vpc_id     = aws_vpc.db-vpc.id
  cidr_block = "10.1.1.0/24"
  availability_zone = "ca-central-1a"
}

resource "aws_subnet" "subnet2" {
  vpc_id     = aws_vpc.db-vpc.id
  cidr_block = "10.1.2.0/24"
  availability_zone = "ca-central-1b"
}

resource "aws_route_table_association" "subnet1-rt" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_vpc.db-vpc.default_route_table_id
  depends_on = [ aws_subnet.subnet1 ]
}

resource "aws_route_table_association" "subnet2-rt" {
  subnet_id      = aws_subnet.subnet2.id
  route_table_id = aws_vpc.db-vpc.default_route_table_id
  depends_on = [ aws_subnet.subnet2 ]
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.db-vpc.id
}

resource "aws_route" "route-igw" {
  route_table_id            = aws_vpc.db-vpc.default_route_table_id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id                = aws_internet_gateway.igw.id
  depends_on = [ aws_internet_gateway.igw ]
}

resource "aws_default_security_group" "sg_rds" {
  vpc_id      = aws_vpc.db-vpc.id

  ingress {
    from_port   = 3306
    to_port     = 3306
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

resource "aws_db_subnet_group" "rds-sg" {
  name       = "mysql-sg"
  subnet_ids = [aws_subnet.subnet1.id , aws_subnet.subnet2.id]
}

resource "aws_db_instance" "rds" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  name                 = "trialdb"
  username             = "admin"
  password             = "admin1234"
  parameter_group_name = "default.mysql5.7"
  db_subnet_group_name = aws_db_subnet_group.rds-sg.name
  publicly_accessible  = true
  skip_final_snapshot  = true
  depends_on           = [ aws_db_subnet_group.rds-sg ]
}
