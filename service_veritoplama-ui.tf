resource "aws_ecs_task_definition" "veri-toplama-ui-TD" {
  family                   = "veri-toplama-ui-TD"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 2048
  memory                   = 4096
  execution_role_arn       = data.aws_iam_role.ecs_task_execution_role.arn
  container_definitions = jsonencode([
    {
      name   = "container-name"
      image  = "veri-toplama-ui"
      cpu    = 2048
      memory = 4096
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-create-group  = "true"
          awslogs-group         = "/ecs/veri-toplama-ui"
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

resource "aws_lb_target_group" "veri-toplama-ui-tg" {
  name        = "veri-toplama-ui-tg"
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
    Name        = "veri-toplama-ui-tg"
    Environment = var.environment
  }
}

resource "aws_ecs_service" "veri-toplama-ui-service" {
  name            = "veri-toplama-ui-service"
  cluster         = aws_ecs_cluster.base-cluster.id
  task_definition = aws_ecs_task_definition.veri-toplama-ui-TD.id
  desired_count   = 1
  depends_on = [
    aws_ecs_cluster.base-cluster,
    aws_ecs_task_definition.veri-toplama-ui-TD,
    aws_lb_target_group.veri-toplama-ui-tg,
  ]
  launch_type = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.private-subnet-a.id, aws_subnet.private-subnet-b.id]
    security_groups  = [aws_security_group.service-sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.veri-toplama-ui-tg.arn
    container_name   = "container-name"
    container_port   = 80
  }

  lifecycle {
    ignore_changes = [task_definition]
  }
}

resource "aws_lb" "veri-toplama-ui-alb" {
  name               = "veri-toplama-ui"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["sg-09d6376212dfa6ea1"] // Todo change
  subnets            = [aws_subnet.public-subnet-a.id, aws_subnet.public-subnet-b.id]

  enable_deletion_protection = true

  tags = {
    Name = "veri-toplama-ui-alb"
  }
}

resource "aws_wafv2_web_acl_association" "veri-toplama-ui-alb" {
  resource_arn = aws_lb.veri-toplama-ui-alb.arn
  web_acl_arn  = aws_wafv2_web_acl.generic.arn
}

resource "aws_lb_listener" "veri-toplama-ui-alb-listener" {
  load_balancer_arn = aws_lb.veri-toplama-ui-alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.veri-toplama-ui-tg.arn
  }
  depends_on = [
    aws_lb.veri-toplama-ui-alb
  ]
}

resource "aws_lb_listener_rule" "veri-toplama-ui-rule" {
  listener_arn = aws_lb_listener.veri-toplama-ui-alb-listener.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.veri-toplama-ui-tg.arn
  }

  condition {
    path_pattern {
      values = ["*"]
    }
  }
}
