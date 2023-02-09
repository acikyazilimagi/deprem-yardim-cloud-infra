//web api


resource "aws_ecs_task_definition" "label-studio-TD" {
  family                   = "label-studio-TD"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 2048
  memory                   = 4096
  execution_role_arn       = data.aws_iam_role.ecs_task_execution_role.arn
  container_definitions    = jsonencode([
    {
      name             = "container-name"
      image            = "heartexlabs/label-studio:latest"
      cpu              = 2048
      memory           = 4096
      logConfiguration = {
        logDriver = "awslogs"
        options   = {
          awslogs-create-group  = "true"
          awslogs-group         = "/ecs/label-studio"
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
        }
      }
      essential    = true
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
        }
      ]
    }
  ])
}

resource "aws_lb_target_group" "label-studio-tg" {
  name        = "label-studio-tg"
  port        = 8080
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.vpc.id
  health_check {
    enabled  = true
    path     = "/healthcheck/"
    port     = 8080
    protocol = "HTTP"
  }
  tags = {
    Name        = "label-studio-tg"
    Environment = var.environment
  }
}

resource "aws_ecs_service" "label-studio-service" {
  name            = "label-studio-service"
  cluster         = aws_ecs_cluster.base-cluster.id
  task_definition = aws_ecs_task_definition.label-studio-TD.id
  desired_count   = 1
  depends_on      = [
    aws_ecs_cluster.base-cluster,
    aws_ecs_task_definition.label-studio-TD,
    aws_lb_target_group.label-studio-tg,
  ]
  launch_type = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.private-subnet-a.id, aws_subnet.private-subnet-b.id]
    security_groups  = [aws_security_group.service-sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.label-studio-tg.arn
    container_name   = "container-name"
    container_port   = 8080
  }
}


resource "aws_lb_listener_rule" "label-studio-rule" {
  listener_arn = aws_lb_listener.backend-go-alb-listener.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.label-studio-tg.arn
  }

  condition {
    path_pattern {
      values = ["*"]
    }
  }
}
// web api
