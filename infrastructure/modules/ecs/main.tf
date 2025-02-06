resource "aws_ecs_cluster" "ecs_cluster" {
  name = "${var.environment}-ecs-cluster"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
  
}

resource "aws_cloudwatch_log_group" "ecs_patient_logs" {
  name              = "/ecs/patient-service"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "ecs_appointment_logs" {
  name              = "/ecs/appointment-service"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "xray_logs" {
  name              = "/ecs/X-Ray"
  retention_in_days = 30
}




resource "aws_ecs_task_definition" "task_definition" {
  family                = "${var.environment}-task"
  execution_role_arn    = var.execution_role_arn
  task_role_arn         = var.task_role_arn
  network_mode          = "awsvpc"
  container_definitions = jsonencode([
    {
      name      = "patient-service"
      image     = "${var.ecr_patient_repo_url}:latest"  # Dynamically use the ECR URL
      cpu       = 256
      memory    = 1024
      essential = true
      portMappings = [{
        containerPort = 3000
        hostPort      = 3000
      }]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/patient-service"
          awslogs-region        = "eu-north-1"
          awslogs-stream-prefix = "ecs"
        }
       }
    },
    {
      name      = "appointment-service"
      image     = "${var.ecr_appointment_repo_url}:latest"  # Dynamically use the ECR URL
      cpu       = 256
      memory    = 1024
      essential = true
      portMappings = [{
        containerPort = 3001
        hostPort      = 3001
      }]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/appointment-service"
          awslogs-region        = "eu-north-1"
          awslogs-stream-prefix = "ecs"
        }
      }
    },
  {
      name      = "xray-daemon"
      image     = "amazon/aws-xray-daemon"
      cpu       = 50
      memory    = 128
      essential = true
      portMappings = [{ 
        containerPort = 2000
        hostPort      = 2000
        protocol      = "UDP"
       }]
      environment = [
        {
          name  = "AWS_REGION"
          value = "eu-north-1"  # Set your AWS region
        },
       {
          name  = "AWS_XRAY_TRACING_NAME"
          value = "appointment-service-trace"
       },
       {
          name  = "AWS_XRAY_DAEMON_ADDRESS"
          value = "xray.eu-north-1.amazonaws.com:2000"
        },
       {
        name  = "AWS_XRAY_DAEMON_DISABLE_METADATA"
        value = "true"
       },
      {
       name  = "AWS_XRAY_DAEMON_NO_INSTANCE_ID"
       value = "true"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/X-Ray"
          awslogs-region        = "eu-north-1"
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])

  requires_compatibilities = ["FARGATE"]
  memory                  = "2GB"
  cpu                     = "1 vCPU"
}

resource "aws_ecs_service" "patient-service" {
  name            = "patient-service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.task_definition.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = var.public_subnet_ids
    security_groups  = [var.ecs_security_group_id]
    assign_public_ip = true
  }
   load_balancer {
    target_group_arn = var.patient_tg_arn
    container_name   = "patient-service"
    container_port   = 3000
  }
}


resource "aws_ecs_service" "appointment_service" {
  name            = "appointment-service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.task_definition.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.public_subnet_ids
    security_groups  = [var.ecs_security_group_id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = var.appointment_tg_arn
    container_name   = "appointment-service"
    container_port   = 3001
  }
}



##prometheus##

resource "aws_ecs_task_definition" "prometheus" {
  family                   = "prometheus-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([
    {
      name      = "prometheus"
      image     = "prom/prometheus:v2.37.0"
      essential = true
      portMappings = [
        {
          containerPort = 9090
          hostPort      = 9090
        }
      ]
   
    logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/prometheus"
          awslogs-region        = "eu-north-1"
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}


resource "aws_ecs_task_definition" "grafana" {
  family                   = "grafana-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn
  cpu                      = 512
  memory                   = 1024

  container_definitions = jsonencode([
    {
      name      = "grafana"
      image     = "grafana/grafana:9.0.0"
      essential = true
      environment = [
        {
          name  = "GF_SECURITY_ADMIN_PASSWORD"
          value = "admin123"
        }
      ]
      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/grafana"
          awslogs-region        = "eu-north-1"
          awslogs-stream-prefix = "ecs"
        }
      }
     
    }
  ])
}


resource "aws_ecs_service" "prometheus" {
  name            = "prometheus-service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.prometheus.arn
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = var.public_subnet_ids
    security_groups = [var.ecs_security_group_id]
    assign_public_ip = true
  }

  desired_count = 1
}

resource "aws_ecs_service" "grafana" {
  name            = "grafana-service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.grafana.arn
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = var.public_subnet_ids
    security_groups = [var.ecs_security_group_id]
    assign_public_ip = true
  }

  desired_count = 1
}




