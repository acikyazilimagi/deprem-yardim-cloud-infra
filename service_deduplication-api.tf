locals {
  deduplication-api = {
    secrets = {
      DEDUPLICATION_API_KEY     = "/projects/deduplication-api/deduplication-api-key"
      MILVUS_DB_ALIAS           = "/projects/deduplication-api/milvus-db-alias"
      MILVUS_DB_URI             = "/projects/deduplication-api/milvus-db-uri"
      MILVUS_DB_USERNAME        = "/projects/deduplication-api/milvus-db-username"
      MILVUS_DB_PASSWORD        = "/projects/deduplication-api/milvus-db-password"
      MILVUS_DB_SECURE          = "/projects/deduplication-api/milvus-db-secure"
      MILVUS_DB_COLLECTION_NAME = "/projects/deduplication-api/milvus-db-collection-name"
      MILVUS_SEARCH_THRESHOLD   = "/projects/deduplication-api/milvus-search-threshold"
      MODEL_NAME                = "/projects/deduplication-api/model-name"
    }
  }
}

data "aws_secretsmanager_secret" "deduplication-api" {
  for_each = local.deduplication-api.secrets
  name     = each.value
}

data "aws_secretsmanager_secret_version" "deduplication-api" {
  for_each  = local.deduplication-api.secrets
  secret_id = data.aws_secretsmanager_secret.deduplication-api[each.key].id
}

resource "aws_ecs_task_definition" "deduplication-api-TD" {
  family                   = "deduplication-api-TD"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 1024
  memory                   = 2048
  execution_role_arn       = data.aws_iam_role.ecs_task_execution_role.arn
  container_definitions    = jsonencode([
    {
      name             = "container-name"
      image            = "deduplication-api"
      cpu              = 1024
      memory           = 2048
      logConfiguration = {
        logDriver = "awslogs"
        options   = {
          awslogs-create-group  = "true"
          awslogs-group         = "/ecs/deduplication-api"
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
        }
      }
      essential    = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    }
  ])
}

resource "aws_lb_target_group" "deduplication-api-tg" {
  name        = "deduplication-api-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.vpc.id
  health_check {
    enabled  = true
    path     = "/health-check"
    port     = 80
    protocol = "HTTP"
  }
  tags = {
    Name        = "deduplication-api-tg"
    Environment = var.environment
  }
}

resource "aws_ecs_service" "deduplication-api-service" {
  name            = "deduplication-api"
  cluster         = aws_ecs_cluster.base-cluster.id
  task_definition = aws_ecs_task_definition.deduplication-api-TD.id
  desired_count   = 1
  depends_on      = [
    aws_ecs_cluster.base-cluster,
    aws_ecs_task_definition.deduplication-api-TD,
    aws_lb_target_group.deduplication-api-tg,
  ]
  launch_type = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.private-subnet-a.id, aws_subnet.private-subnet-b.id]
    security_groups  = [aws_security_group.service-sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.deduplication-api-tg.arn
    container_name   = "container-name"
    container_port   = 80
  }

  lifecycle {
    ignore_changes = [task_definition]
  }
}

resource "aws_secretsmanager_secret" "deduplication-api_env" {
  name = "deduplication-api_env"
}

resource "aws_secretsmanager_secret_version" "deduplication-api_env" {
  secret_id     = aws_secretsmanager_secret.deduplication-api_env.id
  secret_string = jsonencode({
    DEDUPLICATION_API_KEY : data.aws_secretsmanager_secret_version.deduplication-api["DEDUPLICATION_API_KEY"].secret_string,
    MILVUS_DB_ALIAS : data.aws_secretsmanager_secret_version.deduplication-api["MILVUS_DB_ALIAS"].secret_string,
    MILVUS_DB_URI : data.aws_secretsmanager_secret_version.deduplication-api["MILVUS_DB_URI"].secret_string,
    MILVUS_DB_USERNAME : data.aws_secretsmanager_secret_version.deduplication-api["MILVUS_DB_USERNAME"].secret_string,
    MILVUS_DB_PASSWORD : data.aws_secretsmanager_secret_version.deduplication-api["MILVUS_DB_PASSWORD"].secret_string,
    MILVUS_DB_SECURE : data.aws_secretsmanager_secret_version.deduplication-api["MILVUS_DB_SECURE"].secret_string,
    MILVUS_DB_COLLECTION_NAME : data.aws_secretsmanager_secret_version.deduplication-api["MILVUS_DB_COLLECTION_NAME"].secret_string,
    MILVUS_SEARCH_THRESHOLD : data.aws_secretsmanager_secret_version.deduplication-api["MILVUS_SEARCH_THRESHOLD"].secret_string,
    MODEL_NAME : data.aws_secretsmanager_secret_version.deduplication-api["MODEL_NAME"].secret_string
  })
}

resource "aws_lb_listener_rule" "deduplication-api-rule" {
  listener_arn = aws_lb_listener.deduplication-api-alb-listener.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.deduplication-api-tg.arn
  }

  condition {
    path_pattern {
      values = ["*"]
    }
  }
}

resource "aws_lb" "deduplication-api-alb" {
  name               = "deduplication-api-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["sg-09d6376212dfa6ea1"]
  subnets            = [aws_subnet.public-subnet-a.id, aws_subnet.public-subnet-b.id]

  enable_deletion_protection = true

  tags = {
    Name = "deduplication-api-alb"
  }
}

resource "aws_wafv2_web_acl_association" "deduplication-api-alb" {
  resource_arn = aws_lb.deduplication-api-alb.arn
  web_acl_arn  = aws_wafv2_web_acl.generic.arn
}

resource "aws_lb_listener" "deduplication-api-alb-listener" {
  load_balancer_arn = aws_lb.deduplication-api-alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.deduplication-api-tg.arn
  }
  depends_on = [
    aws_lb.deduplication-api-alb
  ]
}
