output "ecs_cluster_id" {
  value = aws_ecs_cluster.ecs_cluster.id
}


output "ecs_task_definition_arn" {
  value = aws_ecs_task_definition.task_definition.arn
}


/*output "log_group_name" { 
value = aws_cloudwatch_log_group.ecs_logs.name
}*/
