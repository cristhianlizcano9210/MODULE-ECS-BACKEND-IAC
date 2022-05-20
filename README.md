# DILI-AWS-ECS-BACKEND-IAC
Terraform module to provision a full ECS service (ECS Task Definition + ECS Service + ECR)

## Documentation
To see all the module documentation, do click [here](http://ecs-backend.github.example.co/).

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| family_name | The tasks' family name | string | `n/a` | yes |
| task_network_mode | The task network mode | string | `"awsvpc"` | no |
| task_role_arn | The role the task will use to launch itself | string | `n/a` | no |
| task_execution_role_arn | The role the task will use to run | string | `n/a` | no |
| service_name | The service's name | string | `n/a` | yes |
| service_cluster_arn | The cluster the service will be allocated | string | `n/a` | yes |
| service_load_balancer | The load balancers will be attached to the service | any | `{}` | no |
| service_network_configuration | The service's network configuration | any | `n/a` | yes |
| ecr_name | The name for the docker repository for your service | string | `n/a` | yes |
| task_tags | The task definition's tags | map(string) | `{}` | no |
| service_tags | The service's tags | map(string) | `{}` | no |
| container_definitions | Full compiled JSON with the container definitions for the task family | string | `n/a` | yes |
| task_memory | The memory will be assigned to the entire task | number | `512` | no |
| certificate_arn | Certificate to be associated to the LB listener | string | `""` | no |
| security_group | Ingress and egress rules for the service | any | `{}` | no |
| service_health_check_grace_period_seconds | Time in seconds to wait to start checking the service's health | number | `10` | no |
| service_create_autoscaling_config | Whether to create an autoscaling configuration for the ECS service | bool | `false` | no |
| service_autoscaling_target_max_capacity | The max capacity of task for your ECS service autoscaling configuration | number | `3` | no |
| service_autoscaling_target_min_capacity | The min capacity of task for your ECS service autoscaling configuration | number | `1` | no |
| service_autoscaling_average_mem_utilization_trigger | The percent of average memory utilization to scale up | number | `80` | no |
| service_autoscaling_average_cpu_utilization_trigger | The percent of average cpu utilization to scale up | number | `60` | no |
| service_cluster_name |The cluster the service will be allocated | string | `""` | yes |
| lb_listeners |Specify the load balancers listeners you want to create for the service | any | `[]` | yes |
| target_groups |Specify the target groups configurations you want to create | any | `[]` | yes |
| vpc_id |Your VPC ID | string | `` | yes |
| service_ordered_placement_strategy |Service level strategy rules that are taken into consideration during task placement. List from top to bottom in order of precedence | any | `[]` | no |
| platform_version | version for platform | any | `"1.4.0"` | no |
| ecr_lifepolicy | The policy document. This is a JSON formatted string | any | `null` | yes |
| create_role | This variable allows you to create rol for api | bool | `false` | no|
| custom_role_policy_arns | List of ARNs of IAM policies to attach to IAM role | list(string) | `[""]` | no |
| service_circuit_breaker | Specifies whether to enable deployment circuit breaker | bool | `false` | no |
| service_deployment_maximum_percent | The upper limit (as a percentage of the service's desiredCount) of the number of running tasks | number | `100` | no |
| service_deployment_minimum_healthy_percent | The lower limit (as a percentage of the service's desiredCount) of the number of running tasks | number | `0` | no |

## Outputs

| Name | Description |
|------|-------------|
| this_task_definition_arn | Full ARN of the Task Definition |
| this_task_definition_family | The family of the Task Definition |
| this_task_definition_revision | The revision of the task in a particular family |
| this_service_id | The Amazon Resource Name (ARN) that identifies the service |
| this_service_name | The name of the service |
| this_service_cluster | The Amazon Resource Name (ARN) of cluster which the service runs on |
| this_service_iam_role | The ARN of IAM role used for ELB |
| this_service_desired_count | The number of instances of the task definition |
| this_ecr_arn | Full ARN of the repository |
| this_ecr_name | The name of the repository |
| this_ecr_registry_id | The registry ID where the repository was created |
| this_ecr_repository_url | The URL of the repository |
| this_certificate_arn | The service's certificate ARN |
| this_certificate_domain_name | The service's certificate domain name |
| sg_id | Security group ID |


## Example

`````
data "template_file" "container_definitions_grafana" { # Definición de contenedor 
  template = file("${path.module}/container_definitions/grafana.json")

  vars = {
    account_id = var.map.local.account_id
    region     = var.map.region
  }
}

module "cluster_private" { # creción del cluster 
  source = "github.com/PROJECT-DILI/DILI-AWS-ECS-IAC?ref=v1.0.0"

  create_cluster                     = true
  cluster_name                       = "grafana-cluster0"
  default_capacity_provider_strategy = var.map.defaults.clusters_capacity_provider_strategy
}

module "ecs_backend_grafana" {
  source = "github.com/PROJECT-DILI/DILI-AWS-ECS-BACKEND-IAC?ref=v1.0.0" #llamado al modulo 

  family_name                                         = "ejamplo" # nombre 
  container_definitions                               = data.template_file.container_definitions_grafana.rendered
  task_role_arn                                       = modules.iam.roles.this_iam_role_arn # definicion de rol para el contenedor 
  task_execution_role_arn                             = modules.iam.roles.this_iam_role_arn
  service_name                                        = "ejemplo" # nombre el servicio 
  service_cluster_name                                = module.cluster_private.cluster_name # nombre del contenedor 
  vpc_id                                              = modules.vpc.vpc_id # configuracion de red 
  ecr_name                                            = "ejamplo" # nombre el ecr
  certificate_arn                                     = modules.ec2.alb_0.certificate_arn # certificado del balanceador  a asociar 
  service_create_autoscaling_config                   = true # Habilitación de auto scaling 
  service_autoscaling_average_mem_utilization_trigger = 80 # Metricas de scaling
  service_autoscaling_average_cpu_utilization_trigger = 60

  service_network_configuration = { # configuracion de las subnets
    subnets = var.map.modules.vpc.private_subnets
  }

  security_group = { # configuracion de grupo de seguridad 
    ingress = [
      {
        from_port   = 0
        to_port     = 0
        protocol    = "tcp"
        description = "ECS grafana ingress port"
        cidr_blocks = [var.map.modules.vpc.vpc_cidr_block]
      },
    ]

    egress = [
      {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        description = "ECS grafana egress port"
        cidr_blocks = ["0.0.0.0/0"]
      },
    ]
  }

  lb_listeners = [ # configuración de los listeners
    {
      lb_arn             = modules.ec2.alb_0.this_lb_arn
      port               = local.grafana.lb_listeners[0].port
      protocol           = "HTTPS"
      ssl_policy         = local.lb_listeners_ssl_policy
      target_group_index = 0
    },
  ]

  target_groups = [
    {
      name                 = local.grafana.name
      backend_port         = local.grafana.containers.grafana.port
      target_type          = "ip"
      backend_protocol     = "HTTP"
      deregistration_delay = var.map.defaults.target_group_deregistration_delay
      container_name       = local.grafana.containers.grafana.name

      health_check = {
        enabled             = true
        interval            = var.map.defaults.target_group_health_check_interval
        path                = "/api/health"
        port                = local.grafana.containers.grafana.port
        healthy_threshold   = var.map.defaults.target_group_healthy_threshold
        unhealthy_threshold = var.map.defaults.target_group_unhealthy_threshold
        protocol            = "HTTP"
      }
    },
  ]
}

module "cloudwatch" {
  source = "github.com/PROJECT-DILI/DILI-AWS-CLOUDWATCH-IAC?ref=v1.0.0"

  create_log_group = true
  log_group_name   = "/aws/ecs/servicio"
}


module "ecr" {
  source = "github.com/PROJECT-DILI/DILI-AWS-ECR-IAC?ref=v1.0.0"

  name                 = "servicio"
  image_tag_mutability = "MUTABLE"
}
`````