#AWS ID KEY
provider "aws" {
  region     = "us-east-1"
  access_key = "AKIARRO7EUIOW3CJEYJG"
  secret_key = "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"
}

#VPC
resource "aws_vpc" "Myinstance-vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "Myinstance-vpc"
  }
}



#Subnet-1
resource "aws_subnet" "Public-sub" {
  vpc_id     = aws_vpc.Myinstance-vpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "Public-sub"
  }
}


#Subnet-2
resource "aws_subnet" "Private-sub" {
  vpc_id     = aws_vpc.Myinstance-vpc.id
  cidr_block = "10.0.2.0/24"
 
  tags = {
    Name = "Private-sub"
  }
}



#Security Group
resource "aws_security_group" "Myinstance-sg" {
  name        = "Myinstance-sg"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.Myinstance-vpc.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Myinstance-sg"
  }
}



#Internet Getway
resource "aws_internet_gateway" "Myinstance-igt" {
  vpc_id = aws_vpc.Myinstance-vpc.id

  tags = {
    Name = "Myinstance-igt"
  }
}


#Route Table for IGT
resource "aws_route_table" "Public-rt" {
  vpc_id = aws_vpc.Myinstance-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.Myinstance-igt.id
  }

  tags = {
    Name = "Public-rt"
  }
}



#Route Table Association
resource "aws_route_table_association" "Public-asso" {
  subnet_id      = aws_subnet.Public-sub.id
  route_table_id = aws_route_table.Public-rt.id
}




#Key Pair
resource "aws_key_pair" "Project-key" {
  key_name   = "Project-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCbkZ0xvXZhoK8zXo6sFRSRpNCh78XrzBx4ISq5NnSKDSWHe0tJDdlM3Ptoql8uBrm47O8K+mj376jq92pP+n2alNLJlEZ0hr+3pt/u+u7QpvKwUtMCFJ/QNftjdCrw6CbW1X+YA7Oc/cN3rsSqDogBK0p+XwvzSbeaVAfAVHGXCiJ5+t6j07dxKMDStIuV+hyPMWjkvKhcYNYIiTKwobFnb2w/EkBccEb/bciA5+MKyNISxt4BHXKrPHRK7Q9G1hiN+b4rTs/+w7qpZFpp65bU2SZuV9eL4lV391RVoIBJK6yVlNOwGVf/WxgjFW2Nqf5qV7YgCCFYo0xJCDXNW6Vx root@ip-172-31-51-171.ec2.internal"
}


#AWS IGT Instance

resource "aws_instance" "Myinstance-01" {
  ami           = "ami-006dcf34c09e50022"
  instance_type = "t2.micro"
  subnet_id	= aws_subnet.Public-sub.id
  vpc_security_group_ids = [aws_security_group.Myinstance-sg.id]
  key_name	= "Project-key"

  tags = {
    Name = "Myinstance-01"
  }
}


#AWS NAT Instance
resource "aws_instance" "NAT-instance" {
  ami           = "ami-006dcf34c09e50022"
  instance_type = "t2.micro"
  subnet_id	= aws_subnet.Private-sub.id
  vpc_security_group_ids = [aws_security_group.Myinstance-sg.id]
  key_name	= "Project-key"

  tags = {
    Name = "NAT-instance"
  }
}




#EIP
resource "aws_eip" "Myinstance-ip" {
  instance = aws_instance.Myinstance-01.id
  vpc      = true
}


resource "aws_eip" "NATinstance-ip" {
  vpc      = true
}


#NAT GTW
resource "aws_nat_gateway" "NAT-instance" {
  allocation_id = aws_eip.NATinstance-ip.id
  subnet_id     = aws_subnet.Public-sub.id

}


#Route Table of NAT
resource "aws_route_table" "Private-rt" {
  vpc_id = aws_vpc.Myinstance-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.NAT-instance.id
  }

  tags = {
    Name = "NAT-instance"
  }
}


resource "aws_route_table_association" "Private-assoc" {
  subnet_id      = aws_subnet.Private-sub.id
  route_table_id = aws_route_table.Private-rt.id
}


