terraform {
 required_providers {
   aws = {
     source  = "hashicorp/aws"
     version = "~> 3.0"
   }
 }
}

provider "aws" {
    region = "us-east-2"
    access_key = "AKIAZ7ADEQN2FPQXGWRW"
    secret_key = "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"
}

# Retrieves the default vpc for this region
data "aws_vpc" "default" {
  default = true
}

# Retrieves the subnet ids in the default vpc
data "aws_subnet_ids" "all_default_subnets" {
  vpc_id = data.aws_vpc.default.id
}

resource "aws_security_group" "batch" {
  name   = "batch"
  vpc_id = data.aws_vpc.default.id
  description = "batch VPC security group"
  
  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }
}

# Batch Service Role
resource "aws_iam_role" "aws_batch_service_role" {
  name = "my-project-batch-service-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [{
    "Action": "sts:AssumeRole",
    "Effect": "Allow",
    "Principal": {
      "Service": "batch.amazonaws.com"
    }
  }]
}
EOF
}

resource "aws_iam_role_policy_attachment" "aws_batch_service_role" {
  role       = aws_iam_role.aws_batch_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBatchServiceRole"
}

# ECS Task Execution Role
resource "aws_iam_role" "aws_ecs_task_execution_role" {
  name = "my-project-ecs-task-execution-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "aws_ecs_task_execution_role" {
  role       = aws_iam_role.aws_ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_batch_compute_environment" "batch" {
  compute_environment_name = "my-project-compute-env"
  
  compute_resources {
    max_vcpus = 256
    security_group_ids = [
      aws_security_group.batch.id,
    ]
    subnets = data.aws_subnet_ids.all_default_subnets.ids
    type = "FARGATE"
  }
  service_role = aws_iam_role.aws_batch_service_role.arn
  type         = "MANAGED"
  depends_on = [
    aws_iam_role_policy_attachment.aws_batch_service_role
  ]
}

resource "aws_batch_job_queue" "batch" {
  name     = "my-project-job-queue"
  state    = "ENABLED"
  priority = "0"
  compute_environments = [
    aws_batch_compute_environment.batch.arn,
  ]
}

resource "aws_batch_job_definition" "batch" {
  name = "my-project-job-definition"
  type = "container"
  platform_capabilities = [
    "FARGATE",
  ]
  container_properties = jsonencode({
    command = ["echo", "test"]
    image   = "busybox"

    fargatePlatformConfiguration = {
      platformVersion = "LATEST"
    }

    networkConfiguration = {
      assignPublicIp = "ENABLED"
    }

    resourceRequirements = [
      {
        type  = "VCPU"
        value = "0.25"
      },
      {
        type  = "MEMORY"
        value = "512"
      }
    ]

    executionRoleArn = aws_iam_role.aws_ecs_task_execution_role.arn
  })
}