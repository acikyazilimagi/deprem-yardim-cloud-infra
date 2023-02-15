resource "aws_ecs_task_definition" "go-consumer-TD" {
  family                   = "go-consumer-TD"
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
          awslogs-group         = "/ecs/go-consumer"
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
        }
      }
      essential = true
    }
  ])
}

resource "aws_service_discovery_service" "go-consumer-service" {
  name = "go-consumer-service"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.sd.id

    dns_records {
      ttl  = 10
      type = "A"
    }
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}

resource "aws_ecs_service" "go-consumer-service" {
  name            = "go-consumer-service"
  cluster         = aws_ecs_cluster.base-cluster.id
  task_definition = aws_ecs_task_definition.go-consumer-TD.id
  desired_count   = 1
  depends_on = [
    aws_ecs_cluster.base-cluster,
    aws_ecs_task_definition.go-consumer-TD,
  ]
  launch_type = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.private-subnet-a.id, aws_subnet.private-subnet-b.id]
    security_groups  = [aws_security_group.allow-http-sg.id]
    assign_public_ip = false
  }

  service_registries {
    registry_arn   = aws_service_discovery_service.go-consumer-service.arn
    container_name = "container-name"
  }

  lifecycle {
    ignore_changes = [task_definition]
  }
}
