provider "aws" {
  region="ap-south-1"
}
// creating VPC
resource "aws_vpc" "new_VPC" {
  cidr_block       = "192.168.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames="true"
  tags = {
    Name = "new_VPC"
  }
}
output  "my_vpc_ID" {
value = aws_vpc.new_VPC.id
}
// Creating public subnet 
 resource "aws_subnet" "subnet_1a" {
  vpc_id     =  "${aws_vpc.new_VPC.id}"
  availability_zone = "ap-south-1a"
  cidr_block = "192.168.0.0/24"
  map_public_ip_on_launch = "true"
  
  tags = {
    Name = "subnet_1a"
  }
}
output "my_public_subnet_ID"{
value = aws_subnet.subnet_1a.id
}
// Creating private subnet
resource "aws_subnet" "subnet_1b" {
  vpc_id     =  "${aws_vpc.new_VPC.id}"
  availability_zone = "ap-south-1b"
  cidr_block = "192.168.1.0/24"
  map_public_ip_on_launch = "true"
  
  tags = {
    Name = "subnet_1b"
  }
}
output "my_private_subnet_ID"{
value = aws_subnet.subnet_1a.id
}

// create Internet Gateway
resource "aws_internet_gateway" "my_Internet_gateway" {
  vpc_id ="${aws_vpc.new_VPC.id}"
  tags = {
    Name = "my_Internet_gateway"
  }
}
output "my_Internet_gateway"{
 value = aws_internet_gateway.my_Internet_gateway.id
}
// eggress_only_IG
resource "aws_egress_only_internet_gateway" "EG_IG" {
  vpc_id = "${aws_vpc.new_VPC.id}"
  tags = {
    Name = "EG_IG"
  }
}
// to create route table
resource "aws_route_table" "my_table" {
  vpc_id = "${aws_vpc.new_VPC.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.my_Internet_gateway.id}"
  }
  route {
    ipv6_cidr_block        = "::/0"
    egress_only_gateway_id = "${aws_egress_only_internet_gateway.EG_IG.id}"
  }
  tags = {
    Name = "my_table"
  }
}
output "my_routing_table"{
value=aws_route_table.my_table.id
}

//public  Security Group
resource "aws_security_group" "myPublic_sg" {
  name        = "myPublic_sg"
  description = "Allow SSH,HTTP,ICMP"
  vpc_id      = "${aws_vpc.new_VPC.id}"

  ingress {
    description  =  "TLS from VPC"
    from_port   =  22
    to_port        =  22
    protocol      =  "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
ingress {
    description  = "TLS from VPC"
    from_port   =  80
    to_port        =  80
    protocol      =  "tcp"
    cidr_blocks =  ["0.0.0.0/0"]
 }
ingress {
    description = "TLS from VPC"
    from_port   = -1
    to_port        =  -1
    protocol      =  "icmp"
    cidr_blocks = ["0.0.0.0/0"]
 }
ingress {
    description  = "TLS from VPC"
    from_port   =  443
    to_port        =  443
    protocol      =  "tcp"
    cidr_blocks =  ["0.0.0.0/0"]
 }
  egress {
    from_port   = 0
    to_port       =  0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "myPublic_sg"
  }
}
output "myPublic_sg"{
value = aws_security_group.myPublic_sg.id
}
//private security group
resource "aws_security_group" "myPrivate_sg" {
  name        = "myPrivate_sg"
  description = "Allow SSH,HTTP,ICMP"
  vpc_id      = "${aws_vpc.new_VPC.id}"

  ingress {
    description  =  "TLS from VPC"
    from_port   =  3306
    to_port        =  3306
    protocol      =  "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
egress {
    from_port   = 0
    to_port       =  0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "myPrivateNew_sg"
  }
}
output "myPrivate_sg"{
value = aws_security_group.myPrivate_sg.id
}
 
// to create wordpress using public security group

resource "aws_instance" "wordP" {
 ami = "ami-7e257211"
 instance_type="t2.micro"
 subnet_id = aws_subnet.subnet_1a.id
 vpc_security_group_ids = [aws_security_group.myPublic_sg.id]
 key_name = "Mykey"

 tags = { 
 Name = "WordPress Server"
}
}
output "WordPress_server"{
value = aws_instance.wordP.id
}
 
// to create MySQL using private SG

resource "aws_instance" "mysql_server" {
ami = "ami-08706cb5f68222d09"
instance_type= "t2.micro"
 subnet_id = aws_subnet.subnet_1b.id
 vpc_security_group_ids = [aws_security_group.myPublic_sg.id]
 key_name = "Mykey"

 tags = {
 Name = "MySQL_server"
}
}
output "MYSQL_server"{
value = aws_instance.mysql_server.id
}

// attaching elastic ip
resource "aws_eip" "myEIP" {
  vpc = true

  instance                  = "${aws_instance.wordP.id}"
  associate_with_private_ip = "${aws_instance.wordP.private_ip}"
  depends_on                = ["aws_internet_gateway.my_Internet_gateway"]
}
output "myEIP"{
    value = aws_eip.myEIP.id
}

// attaching NAT gateway
resource "aws_nat_gateway" "my_NAT" {
  allocation_id = "aws_eip.myEIP.allocation_id"
  subnet_id     = "aws_subnet.subnet_1b.id"

  tags = {
    Name = "my_NAT"
  }
}
output "my_NAT"{
    value = aws_nat_gateway.my_NAT.id
}