# AWS provider configuration for LocalStack
provider "aws" {
  region                      = "us-east-1"
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true

  endpoints {
    apigateway     = "http://localhost:4566"
    cloudformation = "http://localhost:4566"
    cloudwatch     = "http://localhost:4566"
    dynamodb       = "http://localhost:4566"
    ec2            = "http://localhost:4566"
    es             = "http://localhost:4566"
    firehose       = "http://localhost:4566"
    iam            = "http://localhost:4566"
    kinesis        = "http://localhost:4566"
    lambda         = "http://localhost:4566"
    route53        = "http://localhost:4566"
    redshift       = "http://localhost:4566"
    s3             = "http://s3.localhost.localstack.cloud:4566"
    secretsmanager = "http://localhost:4566"
    ses            = "http://localhost:4566"
    sns            = "http://localhost:4566"
    sqs            = "http://localhost:4566"
    ssm            = "http://localhost:4566"
    stepfunctions  = "http://localhost:4566"
    sts            = "http://localhost:4566"
    elb            = "http://localhost:4566"
    elbv2          = "http://localhost:4566"
    rds            = "http://localhost:4566"
    autoscaling    = "http://localhost:4566"
    events         = "http://localhost:4566"
  }
}

# VPC: The foundational network for our high-availability RDS deployment
resource "aws_vpc" "rds_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "rds-failover-vpc"
  }
}

# Subnets: Two subnets in different Availability Zones for Multi-AZ support
resource "aws_subnet" "subnet_a" {
  vpc_id            = aws_vpc.rds_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "rds-subnet-a"
  }
}

resource "aws_subnet" "subnet_b" {
  vpc_id            = aws_vpc.rds_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "rds-subnet-b"
  }
}

# DB Subnet Group: Groups our subnets for Multi-AZ RDS deployment
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds-failover-subnet-group"
  subnet_ids = [aws_subnet.subnet_a.id, aws_subnet.subnet_b.id]

  tags = {
    Name = "rds-failover-subnet-group"
  }
}

# Security Group: Firewall for the RDS database instance
resource "aws_security_group" "rds_sg" {
  name        = "rds-failover-sg"
  description = "Allow inbound traffic for RDS"
  vpc_id      = aws_vpc.rds_vpc.id

  # Inbound Rule: Allow PostgreSQL traffic (port 5432) from within the VPC
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.rds_vpc.cidr_block]
  }

  # Outbound All: Allow RDS to reach the internet for updates if needed
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds-failover-sg"
  }
}

# RDS DB Instance: High-availability database with automated failover
resource "aws_db_instance" "rds_failover" {
  allocated_storage      = 20
  engine                 = "postgres"
  engine_version         = "13.7"
  instance_class         = "db.t3.micro"
  db_name                = "sysops_lab_db"
  username               = "admin"
  password               = "securepassword123" # Use secrets manager in production
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  # Multi-AZ Support: Enables automated failover to a standby instance
  multi_az = true

  # Backup Management: Enables automated daily backups
  backup_retention_period = 7
  skip_final_snapshot     = true

  tags = {
    Name        = "rds-failover-instance"
    Environment = "SysOps-Lab"
  }
}

# Outputs: Key identifiers for managing the Multi-AZ RDS instance
output "rds_endpoint" {
  value = aws_db_instance.rds_failover.endpoint
}

output "database_name" {
  value = aws_db_instance.rds_failover.db_name
}

output "multi_az_status" {
  value = aws_db_instance.rds_failover.multi_az
}
