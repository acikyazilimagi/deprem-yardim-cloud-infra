locals {
  afetlojistik-api = {
    secrets = {
      db_user = "/projects/afetlojistik-api/db/user"
      db_pass = "/projects/afetlojistik-api/db/pass"
    }
  }
}

data "aws_secretsmanager_secret" "afetlojistik-api" {
  for_each = local.afetlojistik-api.secrets
  name     = each.value
}

data "aws_secretsmanager_secret_version" "afetlojistik-api" {
  for_each  = local.afetlojistik-api.secrets
  secret_id = data.aws_secretsmanager_secret.afetlojistik-api[each.key].id
}

resource "aws_security_group" "afetlojistik-api_db" {
  name   = "afetlojistik-api-db"
  vpc_id = aws_vpc.vpc.id
}

resource "aws_security_group_rule" "docdb" {
  security_group_id = aws_security_group.afetlojistik-api_db.id
  from_port         = 27017
  to_port           = 27017
  cidr_blocks       = [aws_vpc.vpc.cidr_block]
  type              = "ingress"
  protocol          = "tcp"
}

resource "aws_db_subnet_group" "afetlojistik-api" {
  name       = "afetlojistik-api"
  subnet_ids = [aws_subnet.private-subnet-a.id, aws_subnet.private-subnet-b.id]
}

resource "aws_docdb_cluster" "afetlojistik-api" {
  cluster_identifier      = "afetlojistik-api"
  engine                  = "docdb"
  availability_zones      = ["${var.region}a", "${var.region}b", "${var.region}c"]
  backup_retention_period = 5
  master_username         = data.aws_secretsmanager_secret_version.afetlojistik-api["db_user"].secret_string
  master_password         = data.aws_secretsmanager_secret_version.afetlojistik-api["db_pass"].secret_string
  vpc_security_group_ids  = [aws_security_group.afetlojistik-api_db.id]
  db_subnet_group_name    = aws_db_subnet_group.afetlojistik-api.id
  deletion_protection     = true
  skip_final_snapshot     = true
}

resource "aws_docdb_cluster_instance" "afetlojistik-api" {
  cluster_identifier = aws_docdb_cluster.afetlojistik-api.id
  instance_class     = "db.t3.medium"
  identifier         = "afetlojistik-api"
}

resource "aws_secretsmanager_secret" "afetlojistik-api_env" {
  name = "afetlojistik-api-prod-env"
}

resource "aws_secretsmanager_secret_version" "afetlojistik-api_env" {
  secret_id     = aws_secretsmanager_secret.afetlojistik-api_env.id
  secret_string = jsonencode({
    DOCDB_HOST : aws_docdb_cluster.afetlojistik-api.endpoint
    DOCDB_PORT : aws_docdb_cluster.afetlojistik-api.port
    DOCDB_USER : aws_docdb_cluster.afetlojistik-api.master_username
    DOCDB_PASS : aws_docdb_cluster.afetlojistik-api.master_password
    DOCDB_NAME : "afetlojistik-api"
    PORT : 3000
    SWAGGER_ENABLED : true
    # mongodb://[username:password@]host[:port][/[database][?parameter_list]]
    MONGO_URL : "mongodb://${aws_docdb_cluster.afetlojistik-api.master_username}:${aws_docdb_cluster.afetlojistik-api.master_password}@${aws_docdb_cluster.afetlojistik-api.endpoint}:27017/afetlojistik-api??replicaSet=rs0&readPreference=secondaryPreferred&retryWrites=false"
    LOG_LEVEL : "debug"
    #    DISCORD_WEB_HOOK : data.aws_secretsmanager_secret_version.afetlojistik-api["discord_webhook"].secret_string
  })
}

resource "aws_ecs_task_definition" "afetlojistik-api" {
  family                   = "afetlojistik-api"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 2048
  memory                   = 4096
  execution_role_arn       = data.aws_iam_role.ecs_task_execution_role.arn
  container_definitions    = jsonencode([
    {
      name             = "container-name"
      image            = "nginx:latest" //bunu düzelticem
      cpu              = 2048
      memory           = 4096
      logConfiguration = {
        logDriver = "awslogs"
        options   = {
          awslogs-create-group  = "true"
          awslogs-group         = "/ecs/afetlojistik-api"
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

resource "aws_lb_target_group" "afetlojistik-api" {
  name        = "afetlojistik-api"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.vpc.id
  health_check {
    enabled  = true
    path     = "/"
    port     = 80
    protocol = "HTTP"
    matcher  = "200,202,302"
  }
  tags = {
    Name        = "afetlojistik-api"
    Environment = var.environment
  }
}

resource "aws_ecs_service" "afetlojistik-api" {
  name            = "afetlojistik-api"
  cluster         = aws_ecs_cluster.base-cluster.id
  task_definition = aws_ecs_task_definition.afetlojistik-api.id
  desired_count   = 1
  depends_on      = [
    aws_ecs_cluster.base-cluster,
    aws_ecs_task_definition.afetlojistik-api,
    aws_lb_target_group.afetlojistik-api,
  ]
  launch_type = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.private-subnet-a.id, aws_subnet.private-subnet-b.id]
    security_groups  = [aws_security_group.service-sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.afetlojistik-api.arn
    container_name   = "container-name"
    container_port   = 80
  }

  lifecycle {
    ignore_changes = [task_definition]
  }
}


resource "aws_lb_listener_rule" "afetlojistik-api" {
  listener_arn = aws_lb_listener.afetlojistik-api.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.afetlojistik-api.arn
  }

  condition {
    path_pattern {
      values = ["*"]
    }
  }
}

resource "aws_lb" "afetlojistik-api" {
  name               = "afetlojistik-api"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["sg-09d6376212dfa6ea1"] // Todo change
  subnets            = [aws_subnet.public-subnet-a.id, aws_subnet.public-subnet-b.id]

  tags = {
    Name = "afetlojistik-api"
  }
}

resource "aws_lb_listener" "afetlojistik-api" {
  load_balancer_arn = aws_lb.afetlojistik-api.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.afetlojistik-api.arn
  }
  depends_on = [
    aws_lb.afetlojistik-api
  ]
}
