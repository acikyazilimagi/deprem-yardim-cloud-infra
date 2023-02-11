//address-telegram
resource "aws_ecs_task_definition" "address-telegram-TD" {
  family                   = "address-telegram-TD"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = data.aws_iam_role.ecs_task_execution_role.arn
  container_definitions = jsonencode([
    {
      name   = "container-name"
      image  = "nginx"
      cpu    = 512
      memory = 1024
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-create-group  = "true"
          awslogs-group         = "/ecs/address-telegram"
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
        }
      }
      essential = true
    }
  ])

}

resource "aws_ecs_service" "address-telegram-service" {
  name            = "address-telegram-service"
  cluster         = aws_ecs_cluster.base-cluster.id
  task_definition = aws_ecs_task_definition.address-telegram-TD.id
  desired_count   = 1
  depends_on = [
    aws_ecs_cluster.base-cluster,
    aws_ecs_task_definition.address-telegram-TD,
  ]
  launch_type = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.private-subnet-a.id, aws_subnet.private-subnet-b.id]
    security_groups  = [aws_security_group.service-sg.id]
    assign_public_ip = true
  }
}

//address-telegram




//address-twitter
resource "aws_ecs_task_definition" "address-twitter-TD" {
  family                   = "address-twitter-TD"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = data.aws_iam_role.ecs_task_execution_role.arn
  container_definitions = jsonencode([
    {
      name   = "container-name"
      image  = "nginx"
      cpu    = 512
      memory = 1024
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-create-group  = "true"
          awslogs-group         = "/ecs/address-twitter"
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
        }
      }
      essential = true
    }
  ])

}

resource "aws_ecs_service" "address-twitter-service" {
  name            = "address-twitter-service"
  cluster         = aws_ecs_cluster.base-cluster.id
  task_definition = aws_ecs_task_definition.address-twitter-TD.id
  desired_count   = 5
  depends_on = [
    aws_ecs_cluster.base-cluster,
    aws_ecs_task_definition.address-twitter-TD,
  ]
  launch_type = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.private-subnet-a.id, aws_subnet.private-subnet-b.id]
    security_groups  = [aws_security_group.service-sg.id]
    assign_public_ip = true
  }
}

//address-twitter


//address-discord
resource "aws_ecs_task_definition" "address-discord-TD" {
  family                   = "address-discord-TD"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = data.aws_iam_role.ecs_task_execution_role.arn
  container_definitions = jsonencode([
    {
      name   = "container-name"
      image  = "nginx"
      cpu    = 512
      memory = 1024
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-create-group  = "true"
          awslogs-group         = "/ecs/address-discord"
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
        }
      }
      essential = true
    }
  ])

}

resource "aws_ecs_service" "address-discord-service" {
  name            = "address-discord-service"
  cluster         = aws_ecs_cluster.base-cluster.id
  task_definition = aws_ecs_task_definition.address-discord-TD.id
  desired_count   = 1
  depends_on = [
    aws_ecs_cluster.base-cluster,
    aws_ecs_task_definition.address-discord-TD,
  ]
  launch_type = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.private-subnet-a.id, aws_subnet.private-subnet-b.id]
    security_groups  = [aws_security_group.service-sg.id]
    assign_public_ip = true
  }
}

//address-discord


//address-twitch
resource "aws_ecs_task_definition" "address-twitch-TD" {
  family                   = "address-twitch-TD"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = data.aws_iam_role.ecs_task_execution_role.arn
  container_definitions = jsonencode([
    {
      name   = "container-name"
      image  = "nginx"
      cpu    = 512
      memory = 1024
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-create-group  = "true"
          awslogs-group         = "/ecs/address-twitch"
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
        }
      }
      essential = true
    }
  ])

}

resource "aws_ecs_service" "address-twitch-service" {
  name            = "address-twitch-service"
  cluster         = aws_ecs_cluster.base-cluster.id
  task_definition = aws_ecs_task_definition.address-twitch-TD.id
  desired_count   = 1
  depends_on = [
    aws_ecs_cluster.base-cluster,
    aws_ecs_task_definition.address-twitch-TD,
  ]
  launch_type = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.private-subnet-a.id, aws_subnet.private-subnet-b.id]
    security_groups  = [aws_security_group.service-sg.id]
    assign_public_ip = true
  }
}

//address-twitch


//address-data-excell
resource "aws_ecs_task_definition" "address-data-excell-TD" {
  family                   = "address-data-excell-TD"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = data.aws_iam_role.ecs_task_execution_role.arn
  container_definitions = jsonencode([
    {
      name   = "container-name"
      image  = "nginx"
      cpu    = 512
      memory = 1024
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-create-group  = "true"
          awslogs-group         = "/ecs/address-data-excell"
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
        }
      }
      essential = true
    }
  ])

}

resource "aws_ecs_service" "address-data-excell-service" {
  name            = "address-data-excell-service"
  cluster         = aws_ecs_cluster.base-cluster.id
  task_definition = aws_ecs_task_definition.address-data-excell-TD.id
  desired_count   = 1
  depends_on = [
    aws_ecs_cluster.base-cluster,
    aws_ecs_task_definition.address-data-excell-TD,
  ]
  launch_type = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.private-subnet-a.id, aws_subnet.private-subnet-b.id]
    security_groups  = [aws_security_group.service-sg.id]
    assign_public_ip = true
  }
}

//address-data-excell
