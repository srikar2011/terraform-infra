resource "aws_security_group" "ecs_sg" {
  vpc_id = var.vpc_id

  ingress {
    from_port       = 3000
    to_port         = 3001
    protocol        = "tcp"
    security_groups = [var.alb_sg]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecs_cluster" "main" {
  name = "travelmemory-${var.env}"
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole-${var.env}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}



resource "aws_ecs_task_definition" "backend" {
  family                   = "backend-${var.env}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([{
    name  = "backend"
    image = "${var.backend_repo}:${var.image_tag}"

    portMappings = [{ containerPort = 3001 }]

    environment = [
      { name = "MONGO_URI", value = var.mongo_uri },
      { name = "PORT", value = "3001" }
    ]
  }])
}

resource "aws_ecs_task_definition" "frontend" {
  family                   = "frontend-${var.env}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([{
    name  = "frontend"
    image = "${var.frontend_repo}:${var.image_tag}"

    portMappings = [{ containerPort = 3000 }]
  }])
}

resource "aws_ecs_service" "backend" {
  name            = "backend-${var.env}-${var.deploy_color}"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.backend.arn
  launch_type     = "FARGATE"

  desired_count = 1

  network_configuration {
    subnets          = var.subnets
    assign_public_ip = true
    security_groups  = [aws_security_group.ecs_sg.id]
  }

  load_balancer {
    target_group_arn = var.deploy_color == "blue" ? var.tg_backend_blue : var.tg_backend_green
    container_name   = "backend"
    container_port   = 3001
  }
}

resource "aws_ecs_service" "frontend" {
  name            = "frontend-${var.env}"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.frontend.arn
  launch_type     = "FARGATE"

  desired_count = 1

  network_configuration {
    subnets          = var.subnets
    assign_public_ip = true
    security_groups  = [aws_security_group.ecs_sg.id]
  }

  load_balancer {
    target_group_arn = var.tg_frontend
    container_name   = "frontend"
    container_port   = 3000
  }
}