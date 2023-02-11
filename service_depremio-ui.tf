resource "aws_ecs_task_definition" "depremio-ui" {
  family                   = "depremio-ui"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 2048
  memory                   = 4096
  execution_role_arn       = data.aws_iam_role.ecs_task_execution_role.arn
  container_definitions = jsonencode([
    {
      name   = "container-name"
      image  = "nginx:latest"
      cpu    = 2048
      memory = 4096
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-create-group  = "true"
          awslogs-group         = "/ecs/depremio"
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

resource "aws_lb_target_group" "depremio-ui" {
  name        = "depremio-ui"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.vpc.id
  health_check {
    enabled  = true
    path     = "/"
    port     = 80
    protocol = "HTTP"
  }
  tags = {
    Name        = "depremio-tg"
    Environment = var.environment
  }
}

resource "aws_ecs_service" "depremio-ui" {
  name            = "depremio-ui"
  cluster         = aws_ecs_cluster.base-cluster.id
  task_definition = aws_ecs_task_definition.depremio-ui.id
  desired_count   = 1
  depends_on = [
    aws_ecs_cluster.base-cluster,
    aws_ecs_task_definition.depremio-ui,
    aws_lb_target_group.depremio-ui,
  ]
  launch_type = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.private-subnet-a.id, aws_subnet.private-subnet-b.id]
    security_groups  = [aws_security_group.ecs-default-sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.depremio-ui.arn
    container_name   = "container-name"
    container_port   = 80
  }
}

resource "aws_lb_listener_rule" "depremio-ui" {
  listener_arn = aws_lb_listener.depremio-ui.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.depremio-ui.arn
  }

  condition {
    path_pattern {
      values = ["*"]
    }
  }
}

resource "aws_lb" "depremio-ui" {
  name               = "depremio-ui"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["sg-09d6376212dfa6ea1"] // Todo change
  subnets            = [aws_subnet.public-subnet-a.id, aws_subnet.public-subnet-b.id]

  enable_deletion_protection = true

  tags = {
    Name = "depremio-alb"
  }
}

resource "aws_lb_listener" "depremio-ui" {
  load_balancer_arn = aws_lb.depremio-ui.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.depremio-ui.arn
  }
  depends_on = [
    aws_lb.depremio-ui
  ]
}
