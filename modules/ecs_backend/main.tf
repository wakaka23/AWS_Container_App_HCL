########################
# ECS
########################

# Define ECS task definition
resource "aws_ecs_task_definition" "backend" {
  family                   = "${var.common.env}-backend-def"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 512
  memory                   = 1024
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.task_execution_role.arn
  container_definitions = jsonencode([
    {
      name      = "app"
      image     = "${var.common.account_id}.dkr.ecr.ap-northeast-1.amazonaws.com/container-app-backend:v1"
      cpu       = 256
      memory    = 512
      essential = true
      secrets = [
        {
          name      = "DB_HOST"
          valueFrom = "${var.secrets_manager.secret_for_db_arn}:host::"
        },
        {
          name      = "DB_NAME"
          valueFrom = "${var.secrets_manager.secret_for_db_arn}:dbname::"
        },
        {
          name      = "DB_USERNAME"
          valueFrom = "${var.secrets_manager.secret_for_db_arn}:username::"
        },
        {
          name      = "DB_PASSWORD"
          valueFrom = "${var.secrets_manager.secret_for_db_arn}:password::"
        }
      ]
      portMappings = [{ containerPort = 80 }]
      "readonlyRootFilesystem" : true
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-region : "ap-northeast-1"
          awslogs-group : aws_cloudwatch_log_group.backend.name
          awslogs-stream-prefix : "ecs"
        }
      }
    }
  ])
}

# Define ECS cluster
resource "aws_ecs_cluster" "backend" {
  name = "${var.common.env}-backend-cluster"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# Define ECS service
resource "aws_ecs_service" "backend" {
  name                               = "${var.common.env}-ecs-backend-service"
  cluster                            = aws_ecs_cluster.backend.arn
  task_definition                    = aws_ecs_task_definition.backend.arn
  launch_type                        = "FARGATE"
  platform_version                   = "1.4.0"
  scheduling_strategy                = "REPLICA"
  desired_count                      = 2
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200
  deployment_controller {
    type = "CODE_DEPLOY"
  }
  enable_ecs_managed_tags = true
  network_configuration {
    subnets = var.network.private_subnet_for_container_ids
    security_groups = [
      var.network.security_group_for_backend_container_id
    ]
    assign_public_ip = false
  }
  health_check_grace_period_seconds = 120
  load_balancer {
    target_group_arn = var.alb_internal.alb_target_group_internal_blue_arn
    container_name   = "app"
    container_port   = 80
  }
}

########################
# CodeDeploy
########################
resource "aws_codedeploy_app" "backend" {
  compute_platform = "ECS"
  name             = "${var.common.env}-backend-app"
}
resource "aws_codedeploy_deployment_group" "backend" {
  app_name               = aws_codedeploy_app.backend.name
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"
  deployment_group_name  = "${var.common.env}-ecs-backend-deployment-group"
  service_role_arn       = aws_iam_role.codedeploy.arn
  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }
  ecs_service {
    cluster_name = aws_ecs_cluster.backend.name
    service_name = aws_ecs_service.backend.name
  }
  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [var.alb_internal.alb_listener_internal_blue_arn]
      }
      test_traffic_route {
        listener_arns = [var.alb_internal.alb_listener_internal_green_arn]
      }
      target_group {
        name = var.alb_internal.alb_target_group_internal_blue_name
      }
      target_group {
        name = var.alb_internal.alb_target_group_internal_green_name
      }
    }
  }
  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout    = "STOP_DEPLOYMENT"
      wait_time_in_minutes = 10
    }
    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 60
    }
  }
}

########################
# Service Discovery
########################
resource "aws_service_discovery_private_dns_namespace" "backend" {
  name = "local"
  vpc  = var.network.vpc_id
}
resource "aws_service_discovery_service" "backend" {
  name = "${var.common.env}-ecs-backend-service"
  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.backend.id
    dns_records {
      ttl  = 60
      type = "A"
    }
    routing_policy = "MULTIVALUE"
  }
  health_check_custom_config {
    failure_threshold = 1
  }
}

########################
# CloudWatch Logs
########################

resource "aws_cloudwatch_log_group" "backend" {
  name              = "/ecs/${var.common.env}-backend"
  retention_in_days = 14

  tags = {
    Name = "/ecs/${var.common.env}-backend"
  }
}

########################
# IAM Role
########################

# Define ECS task execution role
resource "aws_iam_role" "task_execution_role" {
  name               = "${var.common.env}-task-execution-role"
  assume_role_policy = data.aws_iam_policy_document.trust_policy_for_task_execution_role.json
}

# Define trust policy for ECS task execution role
data "aws_iam_policy_document" "trust_policy_for_task_execution_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

# Define IAM policy for access to Secrets Manager
resource "aws_iam_policy" "policy_for_access_to_secrets_manager" {
  name   = "${var.common.env}-GettingSecretsPolicy-backend"
  policy = data.aws_iam_policy_document.policy_for_access_to_secrets_manager.json
}

data "aws_iam_policy_document" "policy_for_access_to_secrets_manager" {
  statement {
    effect    = "Allow"
    resources = ["*"]
    actions = [
      "secretsmanager:GetSecretValue",
    ]
  }
}

# Define IAM role policy for ECS task execution role
resource "aws_iam_role_policy_attachments_exclusive" "task_execution_role" {
  role_name = aws_iam_role.task_execution_role.name
  policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",
    aws_iam_policy.policy_for_access_to_secrets_manager.arn
  ]
}

# Define IAM role for CodeDeploy
resource "aws_iam_role" "codedeploy" {
  name               = "${var.common.env}-role-for-codedeploy"
  assume_role_policy = data.aws_iam_policy_document.trust_policy_for_codedeploy.json
}

# Define trust policy for CodeDeploy role
data "aws_iam_policy_document" "trust_policy_for_codedeploy" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["codedeploy.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

# Define IAM role policy for CodeDeploy role
resource "aws_iam_role_policy_attachments_exclusive" "codedeploy" {
  role_name = aws_iam_role.codedeploy.name
  policy_arns = [
    "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
  ]
}
