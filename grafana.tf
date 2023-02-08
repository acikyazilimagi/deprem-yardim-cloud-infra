
//web api


resource "aws_ecs_task_definition" "grafana-TD" {
  family                   = "grafana-TD"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 2048
  memory                   = 4096
  execution_role_arn       = data.aws_iam_role.ecs_task_execution_role.arn
  container_definitions = jsonencode([
    {
      name   = "container-name"
      image  = "grafana/grafana" //bunu düzelticem
      cpu    = 2048
      memory = 4096
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-create-group  = "true"
          awslogs-group         = "/ecs/grafana"
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
        }
      }
      essential = true
      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
        }
      ]
    }
  ])
}

resource "aws_lb_target_group" "grafana-tg" {
  name        = "grafana-tg"
  port        = 3000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.vpc.id
  health_check {
    enabled  = true
    path     = "/healthcheck/"
    port     = 3000
    protocol = "HTTP"
  }
  tags = {
    Name        = "grafana-tg"
    Environment = var.environment
  }
}

resource "aws_ecs_service" "grafana-service" {
  name            = "grafana-service"
  cluster         = aws_ecs_cluster.base-cluster.id
  task_definition = aws_ecs_task_definition.grafana-TD.id
  desired_count   = 1
  depends_on = [
    aws_ecs_cluster.base-cluster,
    aws_ecs_task_definition.grafana-TD,
    aws_lb_target_group.grafana-tg,
  ]
  launch_type = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.private-subnet-a.id, aws_subnet.private-subnet-b.id]
    security_groups  = [aws_security_group.service-sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.grafana-tg.arn
    container_name   = "container-name"
    container_port   = 3000
  }
}


resource "aws_lb_listener_rule" "grafana-rule" {
  listener_arn = aws_lb_listener.grafana-alb-listener.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.grafana-tg.arn
  }

  condition {
    path_pattern {
      values = ["*"]
    }
  }
}
// web api
