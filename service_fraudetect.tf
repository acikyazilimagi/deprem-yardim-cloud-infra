locals {
  fraudetect = {
    secrets = {
      db_user = "/projects/fraudetect/db/user"
      db_pass = "/projects/fraudetect/db/pass"
    }
  }
}

data "aws_secretsmanager_secret" "fraudetect_db_user" {
  name = local.fraudetect.secrets.db_user
}

data "aws_secretsmanager_secret_version" "fraudetect_db_user" {
  secret_id = data.aws_secretsmanager_secret.fraudetect_db_user.id
}

data "aws_secretsmanager_secret" "fraudetect_db_pass" {
  name = local.fraudetect.secrets.db_pass
}

data "aws_secretsmanager_secret_version" "fraudetect_db_pass" {
  secret_id = data.aws_secretsmanager_secret.fraudetect_db_pass.id
}

resource "aws_security_group" "fraudetect_db" {
  name   = "fraudetect-db"
  vpc_id = aws_vpc.vpc.id
}

resource "aws_security_group_rule" "mysql" {
  security_group_id = aws_security_group.fraudetect_db.id
  from_port         = 3306
  to_port           = 3306
  cidr_blocks       = [aws_vpc.vpc.cidr_block]
  type              = "ingress"
  protocol          = "tcp"
}

resource "aws_rds_cluster" "fraudetect" {
  cluster_identifier      = "fraudetect"
  engine                  = "aurora-mysql"
  engine_version          = "5.7.mysql-aurora.2.08.3"
  engine_mode             = "serverless"
  availability_zones      = ["${var.region}a", "${var.region}b"]
  database_name           = "fraudetect"
  backup_retention_period = 5
  master_username         = data.aws_secretsmanager_secret_version.fraudetect_db_user.secret_string
  master_password         = data.aws_secretsmanager_secret_version.fraudetect_db_pass.secret_string
  vpc_security_group_ids  = [aws_security_group.fraudetect_db.id]
}

resource "aws_secretsmanager_secret" "fraudetect_env" {
  name = "fraudetect-prod-env"
}

resource "aws_secretsmanager_secret_version" "fraudetect_env" {
  secret_id = aws_secretsmanager_secret.fraudetect_env.id
  secret_string = jsonencode({
    MYSQL_HOST : aws_rds_cluster.fraudetect.endpoint
    MYSQL_PORT : aws_rds_cluster.fraudetect.port
    MYSQL_USER : aws_rds_cluster.fraudetect.master_username
    MYSQL_PASS : aws_rds_cluster.fraudetect.master_password
  })
}

resource "aws_ecs_task_definition" "fraudetect" {
  family                   = "fraudetect"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 2048
  memory                   = 4096
  execution_role_arn       = data.aws_iam_role.ecs_task_execution_role.arn
  container_definitions = jsonencode([
    {
      name   = "container-name"
      image  = "nginx:latest" //bunu düzelticem
      cpu    = 2048
      memory = 4096
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-create-group  = "true"
          awslogs-group         = "/ecs/fraudetect"
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

resource "aws_lb_target_group" "fraudetect" {
  name        = "fraudetect"
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
    Name        = "fraudetect"
    Environment = var.environment
  }
}

resource "aws_ecs_service" "fraudetect" {
  name            = "fraudetect"
  cluster         = aws_ecs_cluster.base-cluster.id
  task_definition = aws_ecs_task_definition.fraudetect.id
  desired_count   = 1
  depends_on = [
    aws_ecs_cluster.base-cluster,
    aws_ecs_task_definition.fraudetect,
    aws_lb_target_group.fraudetect,
  ]
  launch_type = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.private-subnet-a.id, aws_subnet.private-subnet-b.id]
    security_groups  = [aws_security_group.service-sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.fraudetect.arn
    container_name   = "container-name"
    container_port   = 80
  }

  lifecycle {
    ignore_changes = [task_definition]
  }
}


resource "aws_lb_listener_rule" "fraudetect" {
  listener_arn = aws_lb_listener.fraudetect.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.fraudetect.arn
  }

  condition {
    path_pattern {
      values = ["*"]
    }
  }
}

resource "aws_lb" "fraudetect" {
  name               = "fraudetect"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["sg-09d6376212dfa6ea1"] // Todo change
  subnets            = [aws_subnet.public-subnet-a.id, aws_subnet.public-subnet-b.id]

  enable_deletion_protection = true

  tags = {
    Name = "fraudetect"
  }
}

resource "aws_lb_listener" "fraudetect" {
  load_balancer_arn = aws_lb.fraudetect.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.fraudetect.arn
  }
  depends_on = [
    aws_lb.fraudetect
  ]
}
