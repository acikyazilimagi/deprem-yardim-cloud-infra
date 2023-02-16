locals {
  veritoplama = {
    secrets = {
      mongo_uri = "/projects/veritoplama/mongo/uri"
    }
  }
}

data "aws_secretsmanager_secret" "veritoplama" {
  for_each = local.veritoplama.secrets
  name     = each.value
}

data "aws_secretsmanager_secret_version" "veritoplama" {
  for_each  = local.veritoplama.secrets
  secret_id = data.aws_secretsmanager_secret.veritoplama[each.key].id
}

resource "aws_security_group" "veritoplama" {
  name   = "veritoplama"
  vpc_id = aws_vpc.vpc.id
}

resource "aws_security_group_rule" "veritoplama" {
  security_group_id = aws_security_group.veritoplama.id
  from_port         = 27017
  to_port           = 27017
  cidr_blocks       = [aws_vpc.vpc.cidr_block]
  type              = "ingress"
  protocol          = "tcp"
}

resource "aws_db_subnet_group" "veritoplama" {
  name       = "veritoplama"
  subnet_ids = [aws_subnet.private-subnet-a.id, aws_subnet.private-subnet-b.id]
}

resource "aws_secretsmanager_secret" "veritoplama_env" {
  name = "veritoplama-prod-env"
}

resource "aws_secretsmanager_secret_version" "veritoplama_env" {
  secret_id = aws_secretsmanager_secret.veritoplama_env.id
  secret_string = jsonencode({
    MONGO_URL : data.aws_secretsmanager_secret_version.veritoplama["mongo_uri"].secret_string
  })
}

resource "aws_ecs_task_definition" "veritoplama_api" {
  family                   = "veritoplama-api"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = data.aws_iam_role.ecs_task_execution_role.arn
  container_definitions = jsonencode([
    {
      name   = "container-name"
      image  = "nginx:latest"
      cpu    = 512
      memory = 1024
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-create-group  = "true"
          awslogs-group         = "/ecs/veritoplama-api"
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
        }
      }
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    }
  ])
}

resource "aws_lb_target_group" "veritoplama_api" {
  name        = "veritoplama-api"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.vpc.id
  health_check {
    enabled  = true
    path     = "/healthcheck"
    port     = 80
    protocol = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 10
  }
  tags = {
    Name        = "veritoplama-api-tg"
    Environment = var.environment
  }
}

resource "aws_ecs_service" "veritoplama_api" {
  name            = "veritoplama-api"
  cluster         = aws_ecs_cluster.base-cluster.id
  task_definition = aws_ecs_task_definition.veritoplama_api.id
  desired_count   = 1
  depends_on = [
    aws_ecs_cluster.base-cluster,
    aws_ecs_task_definition.veritoplama_api,
    aws_lb_target_group.veritoplama_api,
  ]
  launch_type = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.private-subnet-a.id, aws_subnet.private-subnet-b.id]
    security_groups  = [aws_security_group.ecs-default-sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.veritoplama_api.arn
    container_name   = "container-name"
    container_port   = 80
  }

  lifecycle {
    ignore_changes = [task_definition]
  }
}

resource "aws_lb_listener_rule" "veritoplama_api" {
  listener_arn = aws_lb_listener.veritoplama_api.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.veritoplama_api.arn
  }

  condition {
    path_pattern {
      values = ["*"]
    }
  }
}

resource "aws_lb" "veritoplama_api" {
  name               = "veritoplama-api"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["sg-09d6376212dfa6ea1"] // Todo change
  subnets            = [aws_subnet.public-subnet-a.id, aws_subnet.public-subnet-b.id]

  enable_deletion_protection = true

  tags = {
    Name = "veritoplama-api-alb"
  }
}

resource "aws_wafv2_web_acl_association" "veritoplama_api" {
  resource_arn = aws_lb.veritoplama_api.arn
  web_acl_arn  = aws_wafv2_web_acl.generic.arn
}

resource "aws_lb_listener" "veritoplama_api" {
  load_balancer_arn = aws_lb.veritoplama_api.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.veritoplama_api.arn
  }
  depends_on = [
    aws_lb.veritoplama_api
  ]
}