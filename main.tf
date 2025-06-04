/***************************
*     create vpc          *
***************************/

resource "aws_vpc" "three-tier-vpc" {
  cidr_block       = var.cidr
  instance_tenancy = "default"

  tags = {
    terraform = "true"
    Name      = "three tier vpc"
  }
}

/***************************
*     public subnet        *
***************************/

resource "aws_subnet" "public-subnet-1" {
  vpc_id                  = aws_vpc.three-tier-vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public subnet us-east-2a"
  }
}

resource "aws_subnet" "public-subnet-2" {
  vpc_id                  = aws_vpc.three-tier-vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-2b"
  map_public_ip_on_launch = true

  tags = {
    Name = "public subnet us-east-2b"
  }
}

/***************************
*     private subnet       *
***************************/

resource "aws_subnet" "private-subnet-1" {
  vpc_id            = aws_vpc.three-tier-vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-2a"

  tags = {
    Name = "private subnet us-east-2a"
  }
}

resource "aws_subnet" "private-subnet-2" {
  vpc_id            = aws_vpc.three-tier-vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-2b"

  tags = {
    Name = "private subnet us-east-2b"
  }
}

/******************************
*    database private subnet  *
*******************************/

resource "aws_subnet" "private-subnet-3" {
  vpc_id            = aws_vpc.three-tier-vpc.id
  cidr_block        = "10.0.5.0/24"
  availability_zone = "us-east-2a"

  tags = {
    Name = "db private subnet us-east-2a"
  }
}

resource "aws_subnet" "private-subnet-4" {
  vpc_id            = aws_vpc.three-tier-vpc.id
  cidr_block        = "10.0.6.0/24"
  availability_zone = "us-east-2b"

  tags = {
    Name = "db private subnet us-east-2b"
  }
}

/***********************************************
*    web auto scaling launch configuration     *
************************************************/

resource "aws_launch_configuration" "three-tier-web-asg-lc" {
  name_prefix                 = "three-tier-web-asg-lc"
  image_id                    = "ami-04f167a56786e4b09"
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  security_groups             = [aws_security_group.webserver-sg.id]

  lifecycle {
    create_before_destroy = true
  }
}

/***********************************************
*     web auto scaling group                   *
************************************************/

resource "aws_autoscaling_group" "three-tier-web-asg" {
  name                 = "three-tier-web-asg"
  launch_configuration = aws_launch_configuration.three-tier-web-asg-lc.id
  min_size             = 2
  max_size             = 4
  desired_capacity     = 2
  vpc_zone_identifier  = [aws_subnet.public-subnet-1.id, aws_subnet.public-subnet-2.id]

  lifecycle {
    create_before_destroy = true
  }
}

/***********************************************
*    app auto scaling launch configuration     *
************************************************/

resource "aws_launch_configuration" "three-tier-app-asg-lc" {
  name_prefix     = "three-tier-app-asg-lc"
  image_id        = "ami-04f167a56786e4b09"
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.appserver-sg.id]

  lifecycle {
    create_before_destroy = true
  }
}

/***********************************************
*     app auto scaling group                   *
************************************************/

resource "aws_autoscaling_group" "three-tier-app-asg" {
  name                 = "three-tier-app-asg"
  launch_configuration = aws_launch_configuration.three-tier-app-asg-lc.id
  min_size             = 2
  max_size             = 4
  desired_capacity     = 2
  vpc_zone_identifier  = [aws_subnet.private-subnet-1.id, aws_subnet.private-subnet-2.id]

  lifecycle {
    create_before_destroy = true
  }
}

/***********************************************
*     web server security group                *
************************************************/

resource "aws_security_group" "webserver-sg" {
  name        = "web-sg"
  description = "allow inbound ssh and https traffic"
  vpc_id      = aws_vpc.three-tier-vpc.id

  ingress {
    protocol    = "tcp"
    self        = true
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    self        = true
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

/***********************************************
*     app server security group                *
***********************************************/

resource "aws_security_group" "appserver-sg" {
  name        = "app-sg"
  description = "allow inbound ssh"
  vpc_id      = aws_vpc.three-tier-vpc.id

  ingress {
    protocol    = "tcp"
    self        = true
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    self        = true
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

/**************************************
*      Database subnet group          *
**************************************/

resource "aws_db_subnet_group" "database-sg" {
  name       = "main"
  subnet_ids = [aws_subnet.private-subnet-3.id, aws_subnet.private-subnet-4.id]

  tags = {
    Name = "My DB subnet group"
  }
}

/************************************
*     Database instance             *
************************************/

resource "aws_db_instance" "db-instance" {
  allocated_storage      = 20
  db_name                = "mydb"
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = "db.t3.micro"
  username               = "admin"
  password               = "password"
  parameter_group_name   = "default.mysql5.7"
  skip_final_snapshot    = true
  db_subnet_group_name   = aws_db_subnet_group.database-sg.id
  vpc_security_group_ids = [aws_security_group.db-sg.id]
  multi_az               = true
}

/**************************************************
*       Security group for Database server        *
**************************************************/

resource "aws_security_group" "db-sg" {
  name        = "db_sg"
  description = "Allows inbound traffic"
  vpc_id      = aws_vpc.three-tier-vpc.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    self        = true
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

/*******************************
*        bastion host         *
********************************/
resource "aws_instance" "bastion-host" {
  ami                         = "ami-04f167a56786e4b09"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public-subnet-1.id
  vpc_security_group_ids      = [aws_security_group.bastion-host-sg.id]
  associate_public_ip_address = true

  tags = {
    Name = "bastion host instance"
  }
}

/***************************************
*     bastion host Security group       *
****************************************/

resource "aws_security_group" "bastion-host-sg" {
  name        = "bastion host sg"
  description = "allows inbound traffic to app server from internet"
  vpc_id      = aws_vpc.three-tier-vpc.id

  ingress {
    protocol    = "tcp"
    self        = true
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

/***********************************************
*           internet gateway                   *
************************************************/

resource "aws_internet_gateway" "internet-gw" {
  vpc_id = aws_vpc.three-tier-vpc.id

  tags = {
    Name = "vpc internet gateway"
  }
}

/***********************************************
*           route table                        *
************************************************/

resource "aws_route_table" "web-route-table" {
  vpc_id = aws_vpc.three-tier-vpc.id
  tags = {
    Name = "webroute table"
  }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet-gw.id
  }
}
resource "aws_route_table" "app-route-table" {
  vpc_id = aws_vpc.three-tier-vpc.id
  tags = {
    Name = "app-route table"
  }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat-gw.allocation_id
  }
}

/***********************************************
*          Public route table association      *
************************************************/

resource "aws_route_table_association" "public-sn1-2a" {
  subnet_id      = aws_subnet.public-subnet-1.id
  route_table_id = aws_route_table.web-route-table.id
}

resource "aws_route_table_association" "public-sn2-2b" {
  subnet_id      = aws_subnet.public-subnet-2.id
  route_table_id = aws_route_table.web-route-table.id
}

/***********************************************
*          private route table association     *
************************************************/
resource "aws_route_table_association" "private-sn1-2a-rt" {
  subnet_id      = aws_subnet.private-subnet-1.id
  route_table_id = aws_route_table.app-route-table.id
}

resource "aws_route_table_association" "private-sn2-2b-rt" {
  subnet_id      = aws_subnet.private-subnet-2.id
  route_table_id = aws_route_table.app-route-table.id
}

resource "aws_route_table_association" "private-sn3-2a-rt" {
  subnet_id      = aws_subnet.private-subnet-3.id
  route_table_id = aws_route_table.app-route-table.id
}

resource "aws_route_table_association" "private-sn4-2a-rt" {
  subnet_id      = aws_subnet.private-subnet-4.id
  route_table_id = aws_route_table.app-route-table.id
}

/***********************************************
*           elastic ip                         *
************************************************/

resource "aws_eip" "elastic-ip" {
  domain = "vpc"


  tags = {
    Name = "Nat eip"
  }
}

/***********************************************
*           Nat Gateway                        *
************************************************/

resource "aws_nat_gateway" "nat-gw" {
  allocation_id = aws_eip.elastic-ip.id
  subnet_id     = aws_subnet.public-subnet-1.id

  tags = {
    Name = "three-tier-nat-gw"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.internet-gw]
}

/**************************************************
*       Application load balancer for webserver   *
***************************************************/

resource "aws_lb" "webserver-asg-alb" {
  name               = "webserver-asg-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.webserver-sg.id]
  subnets            = [aws_subnet.public-subnet-1.id, aws_subnet.public-subnet-2.id]
}

resource "aws_lb_target_group" "alb-target-grp-webserver" {
  name        = "web-alb-target-grp"
  target_type = "instance"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.three-tier-vpc.id
}

/*resource "aws_lb_target_group_attachment" "my-aws-alb1" {
  target_group_arn = aws_lb_target_group.alb-target-grp.id
  target_id        = aws_instance
  port             = 80
}*/

# Create a new ALB Target Group attachment
resource "aws_autoscaling_attachment" "asg-attachment" {
  autoscaling_group_name = aws_autoscaling_group.three-tier-web-asg.id
  lb_target_group_arn    = aws_lb_target_group.alb-target-grp-webserver.arn
}

resource "aws_lb_listener" "lb_lst" {
  load_balancer_arn = aws_lb.webserver-asg-alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb-target-grp-webserver.arn
  }
}

/***********************************************
*  Application load balancer for app server    *
***********************************************/

resource "aws_lb" "appserver-asg-alb" {
  name               = "appserver-asg-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.appserver-sg.id]
  subnets            = [aws_subnet.private-subnet-1.id, aws_subnet.private-subnet-2.id]
}

resource "aws_lb_target_group" "alb-target-grp-appserver" {
  name        = "app-alb-target-grp"
  target_type = "instance"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.three-tier-vpc.id
}

# Create a new ALB Target Group attachment
resource "aws_autoscaling_attachment" "appserver-asg-attachment" {
  autoscaling_group_name = aws_autoscaling_group.three-tier-app-asg.id
  lb_target_group_arn    = aws_lb_target_group.alb-target-grp-appserver.arn
}

resource "aws_lb_listener" "lb_lst-appserver" {
  load_balancer_arn = aws_lb.appserver-asg-alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb-target-grp-appserver.arn
  }
}
