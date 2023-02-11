data "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsServiceRole"
}

resource "aws_ecs_cluster" "base-cluster" {
  name = "base-cluster"
  tags = {
    Name        = "base-cluster"
    Environment = var.environment
  }
}

