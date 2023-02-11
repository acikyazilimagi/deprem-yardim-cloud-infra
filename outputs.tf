output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "ecs_cluster_arn" {
  value = aws_ecs_cluster.base-cluster.arn
}

output "public_subnets" {
  value = [
    aws_subnet.public-subnet-a.id,
    aws_subnet.public-subnet-b.id
  ]
}

output "private_subnets" {
  value = [
    aws_subnet.private-subnet-a.id,
    aws_subnet.private-subnet-b.id
  ]
}
