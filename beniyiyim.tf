
//web api


resource "aws_ecs_task_definition" "beniyiyim-TD" {
  family                   = "beniyiyim-TD"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 2048
  memory                   = 4096
  execution_role_arn       = data.aws_iam_role.ecs_task_execution_role.arn
  container_definitions = jsonencode([
    {
      name   = "container-name"
      image  = "beniyiyim" //bunu düzelticem
      cpu    = 2048
      memory = 4096
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-create-group  = "true"
          awslogs-group         = "/ecs/beniyiyim"
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
        }
      }
      essential = true
      portMappings = [
        {
          containerPort = 8000
          hostPort      = 8000
        }
      ]
    }
  ])
}

resource "aws_lb_target_group" "beniyiyim-tg" {
  name        = "beniyiyim-tg"
  port        = 8000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.vpc.id
  health_check {
    enabled  = true
    path     = "/"
    port     = 8000
    protocol = "HTTP"
  }
  tags = {
    Name        = "beniyiyim-tg"
    Environment = var.environment
  }
}

resource "aws_ecs_service" "beniyiyim-service" {
  name            = "beniyiyim-service"
  cluster         = aws_ecs_cluster.base-cluster.id
  task_definition = aws_ecs_task_definition.beniyiyim-TD.id
  desired_count   = 1
  depends_on = [
    aws_ecs_cluster.base-cluster,
    aws_ecs_task_definition.beniyiyim-TD,
    aws_lb_target_group.beniyiyim-tg,
  ]
  launch_type = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.private-subnet-a.id, aws_subnet.private-subnet-b.id]
    security_groups  = [aws_security_group.service-sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.beniyiyim-tg.arn
    container_name   = "container-name"
    container_port   = 8000
  }
}


resource "aws_lb_listener_rule" "beniyiyim-rule" {
  listener_arn = aws_lb_listener.beniyiyim-alb-listener.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.beniyiyim-tg.arn
  }

  condition {
    path_pattern {
      values = ["*"]
    }
  }
}
// web api
