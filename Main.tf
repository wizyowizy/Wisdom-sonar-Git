# configured aws provider with proper credentials
provider "aws" {
  region     = var.region
  profile    = "default"
}


# Create a VPC

resource "aws_vpc" "prodvpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = true

  tags = {
    Name = "production_vpc"
  }
}

# Create a Subnet

resource "aws_subnet" "prodsubnet1" {
  vpc_id            = aws_vpc.prodvpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
  
  tags = {
    Name = "prod-subnet"
  }
}

#Create the Internet Gateway and attach it to the VPC
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.prodvpc.id

  tags = {
    Name = "New"
  }
}

# Create a Route Table
resource "aws_route_table" "prodroute" {
  vpc_id = aws_vpc.prodvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "RT"
  }
}


#Associate the subnet with the Route Table
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.prodsubnet1.id
  route_table_id = aws_route_table.prodroute.id
}

# Create a Security Group for the EC2 Instance
resource "aws_security_group" "allow_web" {
  name        = "allow_web"
  description = "Allow webserver inbound traffic"
  vpc_id      = aws_vpc.prodvpc.id

  ingress {
    description = "Web Traffic from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    #cidr_blocks = ["${var.my_ip}/32"]
    cidr_blocks = ["0.0.0.0/0"]

  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }
  ingress {
    description = "JENKINS & TOMCAT"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }

  ingress {
    description = "NEXUS"
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }

  ingress {
    description = "SONAR"
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }
  
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1" # Any ip address/ any protocol
    cidr_blocks      = ["0.0.0.0/0"]
    
  }

  tags = {
    Name = "allow_tls"
  }
}

# use data source to get a registered ubuntu ami
data "aws_ami" "ubuntu" {

  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

# Create the EC2 instance and assign key pair
resource "aws_instance" "firstinstance" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.large"
  vpc_security_group_ids = [aws_security_group.allow_web.id]
  subnet_id              = aws_subnet.prodsubnet1.id
  key_name               = "wizyKP"
  availability_zone      = "us-east-1a"
  user_data              =  "${file("install_jenkins.sh")}"


  tags = {
    Name = "Jenkins_Server"
  }
}


resource "aws_instance" "secondinstance" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.allow_web.id]
  subnet_id              = aws_subnet.prodsubnet1.id
  key_name               = "wizyKP"
  availability_zone      = "us-east-1a"
  user_data              =  "${file("install_tomcat.sh")}"
  


  tags = {
    Name = "Tomcat_Server"
  }
}

resource "aws_instance" "thirdinstance" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.xlarge"
  vpc_security_group_ids = [aws_security_group.allow_web.id]
  subnet_id              = aws_subnet.prodsubnet1.id
  key_name               = "wizyKP"
  availability_zone      = "us-east-1a"
  user_data              =  "${file("install_sonarqube.sh")}"
  


  tags = {
    Name = "SonarQube_Server"
  }
}

resource "aws_instance" "fourthinstance" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.xlarge"
  vpc_security_group_ids = [aws_security_group.allow_web.id]
  subnet_id              = aws_subnet.prodsubnet1.id
  key_name               = "wizyKP"
  availability_zone      = "us-east-1a"
  user_data              =  "${file("install_nexus.sh")}"
  


  tags = {
    Name = "Nexus_Server"
  }
}

# print the url of the jenkins server
output "Jenkins_website_url" {
  value     = join ("", ["http://", aws_instance.firstinstance.public_ip, ":", "8080"])
  description = "Jenkins Server which is firstinstance from resource block"
}

# print the url of the tomcat server
output "Tomcat_website_url2" {
  value     = join ("", ["http://", aws_instance.secondinstance.public_ip, ":", "8080"])
  description = "Tomcat Server is secondinstance"
}


# print the url of the Sonarqube server
output "Sonarqube_website_url3" {
  value     = join ("", ["http://", aws_instance.thirdinstance.public_ip, ":", "9000"])
  description = "Sonarqube Server is thirdinstance"
}
# print the url of the Nexus server
output "Nexus_website_url4" {
  value     = join ("", ["http://", aws_instance.fourthinstance.public_ip, ":", "8081"])
  description = "Nexus Server is fourthinstance"
}



