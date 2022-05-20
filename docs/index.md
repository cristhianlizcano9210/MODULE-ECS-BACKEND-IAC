## IaC module - ECS Backend 

### Content
- [Creating a Service](#creating-a-Service)

<a name="creating-a-Service"></a>
#### Creating a Service

```hcl
locals {
  name = "example"
  port = 8001
}

module ecs_cluster_private_virginia {
  source = "github.com/PROJECT-DILI/DILI-AWS-ECR-IAC?ref=v1.0.0"


  providers = {
    aws = aws.virginia
  }s

  create_cluster = true
  cluster_name   = "private"

  default_capacity_provider_strategy = [
    {
      name   = "FARGATE_SPOT"
      weight = 5
      base   = 5
    },
  ]
}

data template_file ecs_creation_adapter_containers_definition {
  template = file("${path.module}/containers_definition.json")

  vars = {
    account_id     = "111556193541"
    region         = "us-east-1"
    container_name = local.name
    container_port = local.port
    ecr_name       = local.name
  }
}

module ecs_backend_example_virginia {
  source = "github.com/PROJECT-DILI/DILI-AWS-ECS-BACKEND-IAC?ref=v1.0.0"

  providers = {
    aws = aws.virginia
  }

  family_name             = local.name
  container_definitions   = data.template_file.ecs_creation_adapter_containers_definition.rendered
  service_name            = local.name
  create_role             = true 
  service_cluster_name    = module.ecs_cluster_private_virginia.cluster_name
  service_cluster_arn     = module.ecs_cluster_private_virginia.this_ecs_cluster_arn
  vpc_id                  = "vpc-03567811864524fc9"
  certificate_arn         = "arn:aws:acm:us-east-1:111556193541:certificate/e4359352-8b47-45bb-8573-c0c89fae89fd"
  ecr_name                = local.name
  custom_role_policy_arns = ["arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"]

  service_network_configuration = {
    subnets = ["subnet-05f629e583a457ae5"]
  }

  lb_listeners = [
    {
      lb_arn             = "arn:aws:elasticloadbalancing:us-east-1:111556193541:loadbalancer/app/unicef-alb-0/703023603619e035"
      port               = local.port
      protocol           = "TLS"
      ssl_policy         = "ELBSecurityPolicy-TLS-1-2-Ext-2019-06"
      target_group_index = 0
    }
  ]

  target_groups = [
    {
      name                 = local.name
      backend_port         = local.port
      target_type          = "ip"
      backend_protocol     = "TCP"
      deregistration_delay = 0
      container_name       = local.name

      health_check = {
        enabled             = true
        interval            = 10
        path                = "/actuator/health"
        port                = local.port
        healthy_threshold   = 3
        unhealthy_threshold = 3
        protocol            = "HTTP"
      }
    }
  ]

  security_group = {
    ingress = [
      {
        from_port   = local.port
        to_port     = local.port
        protocol    = "tcp"
        description = "ECS ${local.name} ingress port"
        cidr_blocks = ["10.0.54.0/24"]
      },
    ]

    egress = [
      {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        description = "ECS ${local.name} egress port"
        cidr_blocks = ["0.0.0.0/0"]
      },
    ]
  }
}
```